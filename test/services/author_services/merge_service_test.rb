require "test_helper"

class AuthorServices::MergeServiceTest < ActiveSupport::TestCase
  let(:target) { authors(:merge_target) }
  subject { AuthorServices::MergeService.new(target) }

  describe "#call" do
    it "transfers books to the target, skips duplicates and destroys the merged author" do
      source = authors(:merge_source)

      result = subject.call([ source ])

      _(result[:success]).must_equal true
      _(result[:merged_count]).must_equal 1

      # shared_book was already on the target, so it must not be duplicated
      _(target.reload.books.count).must_equal 2
      _(target.books).must_include books(:source_book)
      _(target.books).must_include books(:shared_book)

      _(Author.exists?(source.id)).must_equal false
    end

    it "fails when no authors are given" do
      result = subject.call([])

      _(result[:success]).must_equal false
      _(result[:error]).must_equal "No authors provided for merging"
    end

    it "refuses to merge authors owned by another user" do
      other = authors(:brandon_other_user)

      result = subject.call([ other ])

      _(result[:success]).must_equal false
      _(result[:error]).must_equal "Invalid authors for merging"
      _(Author.exists?(other.id)).must_equal true
    end
  end
end
