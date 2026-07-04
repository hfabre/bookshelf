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
end
