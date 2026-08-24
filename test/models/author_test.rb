require "test_helper"

describe Author do
  describe "validations" do
    let(:author) { Author.new(name: "A Unique Author", user: users(:one)) }

    it "is valid with a name and user" do
      _(author).must_be :valid?
    end

    it "requires a name" do
      author.name = nil
      _(author).wont_be :valid?
      _(author.errors[:name]).must_include "can't be blank"
    end

    it "scopes name uniqueness to the user" do
      existing = authors(:tolkien)

      duplicate = Author.new(name: existing.name, user: existing.user)
      _(duplicate).wont_be :valid?
      _(duplicate.errors[:name]).must_include "has already been taken"

      other_user = Author.new(name: existing.name, user: users(:two))
      _(other_user).must_be :valid?
    end
  end

  describe "#merge_with!" do
    let(:author) { authors(:tolkien) }

    it "returns true when the merge service succeeds" do
      service = Minitest::Mock.new
      service.expect(:call, { success: true }) { true }

      AuthorServices::MergeService.stub(:new, ->(*) { service }) do
        _(author.merge_with!([ authors(:lewis) ])).must_equal true
      end

      assert_mock service
    end

    it "returns false when the merge service fails" do
      service = Minitest::Mock.new
      service.expect(:call, { success: false, error: "nope" }) { true }

      AuthorServices::MergeService.stub(:new, ->(*) { service }) do
        _(author.merge_with!([ authors(:lewis) ])).must_equal false
      end

      assert_mock service
    end
  end

  describe "#similar" do
    # Fixtures skip the after_commit callbacks that maintain the FTS index
    before { Author.rebuild_search_index }

    it "returns nothing when the author name is blank" do
      _(Author.new(name: "", user: users(:one)).similar).must_be_empty
    end

    it "finds same-user authors matching the name, excluding self and other users" do
      results = authors(:sanderson).similar

      _(results).must_include authors(:brandon_mull)
      _(results).wont_include authors(:sanderson)          # self
      _(results).wont_include authors(:brandon_other_user) # different user
      _(results).wont_include authors(:tolkien)            # same user, no shared token
    end

    it "stops matching a destroyed author" do
      author = users(:one).authors.create!(name: "Zzz Indexed Author")
      other = users(:one).authors.create!(name: "Zzz Indexed Twin")
      _(other.similar).must_include author

      author.destroy

      _(other.reload.similar).wont_include author
    end
  end
end
