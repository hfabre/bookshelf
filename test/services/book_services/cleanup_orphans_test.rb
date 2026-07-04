require "test_helper"

class BookServices::CleanupOrphansTest < ActiveSupport::TestCase
  let(:user) { users(:one) }

  it "destroys series and authors that have no books" do
    serie = user.series.create!(name: "Empty Serie")
    author = user.authors.create!(name: "Empty Author")

    BookServices::CleanupOrphans.call([ serie, author ])

    _(Serie.exists?(serie.id)).must_equal false
    _(Author.exists?(author.id)).must_equal false
  end

  it "keeps series and authors that still have books" do
    serie = user.series.create!(name: "Kept Serie")
    author = user.authors.create!(name: "Kept Author")
    book = user.books.create!(filename: "k.epub", epub_content: "x", title: "K", serie: serie)
    book.authors << author

    BookServices::CleanupOrphans.call([ serie, author ])

    _(Serie.exists?(serie.id)).must_equal true
    _(Author.exists?(author.id)).must_equal true
  end

  it "is safe with nil, duplicate and already-removed records" do
    serie = user.series.create!(name: "Gone Serie")
    serie_id = serie.id
    serie.destroy

    BookServices::CleanupOrphans.call([ nil, serie, serie ])

    _(Serie.exists?(serie_id)).must_equal false
  end
end
