require "test_helper"

class CleanupOrphansJobTest < ActiveSupport::TestCase
  let(:user) { users(:one) }

  describe "#perform" do
    it "deletes series and authors that have no books" do
      empty_serie = user.series.create!(name: "Empty Serie")
      empty_author = user.authors.create!(name: "Empty Author")
      kept_serie = user.series.create!(name: "Kept Serie")
      user.books.create!(filename: "keep.epub", epub_content: "x", title: "Keep", serie: kept_serie)

      CleanupOrphansJob.new.perform

      _(Serie.exists?(empty_serie.id)).must_equal false
      _(Author.exists?(empty_author.id)).must_equal false
      _(Serie.exists?(kept_serie.id)).must_equal true
    end
  end
end
