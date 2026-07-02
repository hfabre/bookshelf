require "test_helper"

class SerieServices::MergeServiceTest < ActiveSupport::TestCase
  let(:target) { series(:target) }
  subject { SerieServices::MergeService.new(target) }

  describe "#call" do
    it "moves the books into the target and destroys the merged series" do
      to_merge = series(:to_merge)

      result = subject.call([ to_merge ])

      _(result[:success]).must_equal true
      _(result[:merged_count]).must_equal 1
      _(books(:merged_book_one).reload.serie).must_equal target
      _(books(:merged_book_two).reload.serie).must_equal target
      _(Serie.exists?(to_merge.id)).must_equal false
    end

    it "fails when no series are given" do
      result = subject.call([])

      _(result[:success]).must_equal false
      _(result[:error]).must_equal "No series provided for merging"
    end

    it "refuses to merge series owned by another user" do
      other = series(:other_user)

      result = subject.call([ other ])

      _(result[:success]).must_equal false
      _(result[:error]).must_equal "Invalid series for merging"
      _(Serie.exists?(other.id)).must_equal true
    end
  end
end
