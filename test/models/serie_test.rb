require "test_helper"

describe Serie do
  describe "validations" do
    let(:serie) { Serie.new(name: "A Unique Name", user: users(:one)) }

    it "is valid with a name and user" do
      _(serie).must_be :valid?
    end

    it "requires a name" do
      serie.name = nil
      _(serie).wont_be :valid?
      _(serie.errors[:name]).must_include "can't be blank"
    end

    it "scopes name uniqueness to the user" do
      existing = series(:target)

      duplicate = Serie.new(name: existing.name, user: existing.user)
      _(duplicate).wont_be :valid?
      _(duplicate.errors[:name]).must_include "has already been taken"

      other_user = Serie.new(name: existing.name, user: users(:two))
      _(other_user).must_be :valid?
    end

    it "only allows a rating between 1 and 5" do
      serie.rating = 0
      _(serie).wont_be :valid?

      serie.rating = 6
      _(serie).wont_be :valid?

      serie.rating = 3
      _(serie).must_be :valid?

      serie.rating = nil
      _(serie).must_be :valid?
    end
  end

  describe "reading filters" do
    let(:user) { users(:two) }

    it ".to_read returns series that are unset, unread or reading, never finished" do
      unset = user.series.create!(name: "Unset")
      unread = user.series.create!(name: "Unread", reading_state: "unread")
      reading = user.series.create!(name: "Reading", reading_state: "reading")
      finished = user.series.create!(name: "Finished", reading_state: "finished")

      result = user.series.to_read
      _(result).must_include unset
      _(result).must_include unread
      _(result).must_include reading
      _(result).wont_include finished
    end

    it ".to_reread returns finished series that are not rated" do
      unrated = user.series.create!(name: "Finished Unrated", reading_state: "finished")
      rated = user.series.create!(name: "Finished Rated", reading_state: "finished", rating: 4)
      reading = user.series.create!(name: "Reading", reading_state: "reading")

      result = user.series.to_reread
      _(result).must_include unrated
      _(result).wont_include rated
      _(result).wont_include reading
    end
  end

  describe "#merge_with!" do
    let(:serie) { series(:target) }

    it "returns true when the merge service succeeds" do
      service = Minitest::Mock.new
      service.expect(:call, { success: true }) { true }

      SerieServices::MergeService.stub(:new, ->(*) { service }) do
        _(serie.merge_with!([ series(:to_merge) ])).must_equal true
      end

      assert_mock service
    end

    it "returns false when the merge service fails" do
      service = Minitest::Mock.new
      service.expect(:call, { success: false, error: "nope" }) { true }

      SerieServices::MergeService.stub(:new, ->(*) { service }) do
        _(serie.merge_with!([ series(:to_merge) ])).must_equal false
      end

      assert_mock service
    end
  end

  describe "#similar" do
    # Fixtures skip the after_commit callbacks that maintain the FTS index
    before { Serie.rebuild_search_index }

    it "returns nothing when the serie name is blank" do
      _(Serie.new(name: "", user: users(:one)).similar).must_be_empty
    end

    it "finds same-user series matching the name, excluding self and other users" do
      results = series(:naruto).similar

      _(results).must_include series(:naruto_shippuden)
      _(results).wont_include series(:naruto)            # self
      _(results).wont_include series(:naruto_other_user) # different user
      _(results).wont_include series(:target)            # same user, no shared token
    end

    it "does not raise on names containing FTS5-special punctuation" do
      serie = Serie.new(name: "Vol.2: A-B", user: users(:one))

      _(serie.similar.to_a).must_be_kind_of Array
    end

    it "ranks the most relevant match ahead of common-token matches within the limit" do
      user = users(:one)
      # noise sharing only the common stopword-like tokens "de"/"la"
      12.times { |i| user.series.create!(name: "Le Seigneur de la Guerre #{i}") }
      best = user.series.create!(name: "L'Âge de la folie")
      source = user.series.create!(name: "L'âge de la folie")
      Serie.rebuild_search_index

      _(source.similar(5)).must_include best
    end
  end

  describe "search index upkeep" do
    let(:user) { users(:one) }

    it "stops matching a destroyed serie" do
      serie = user.series.create!(name: "Zzz Indexed Serie")
      other = user.series.create!(name: "Zzz Indexed Twin")
      _(other.similar).must_include serie

      serie.destroy

      _(other.reload.similar).wont_include serie
      _(indexed_names).wont_include "Zzz Indexed Serie"
    end

    it "matches a renamed serie by its new name, not its old one" do
      serie = user.series.create!(name: "Zzz Original Name")

      serie.update!(name: "Zzz Replacement Name")

      _(indexed_names).must_include "Zzz Replacement Name"
      _(indexed_names).wont_include "Zzz Original Name"
    end

    it "clears rows left behind when rebuilding" do
      Serie.connection.execute("INSERT INTO series_fts (rowid, name, user_id) VALUES (123456, 'Zzz Orphan Row', 1)")

      Serie.rebuild_search_index

      _(indexed_names).wont_include "Zzz Orphan Row"
    end

    def indexed_names
      Serie.connection.select_values("SELECT name FROM series_fts")
    end
  end
end
