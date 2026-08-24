require "test_helper"

class BookServices::IndexPreviewsTest < ActiveSupport::TestCase
  let(:user) { users(:one) }

  describe ".for_series" do
    it "counts the books and picks the first one with a cover" do
      serie = user.series.create!(name: "Preview Serie")
      user.books.create!(filename: "p1.epub", epub_content: "x", title: "P1", serie: serie, serie_index: 1)
      with_cover = user.books.create!(filename: "p2.epub", epub_content: "x", title: "P2", serie: serie, serie_index: 2,
                                      cover_bytes: "img", cover_type: "image/png")

      previews = BookServices::IndexPreviews.for_series([ serie ])

      _(previews.book_count(serie)).must_equal 2
      _(previews.cover_book(serie).id).must_equal with_cover.id
    end

    it "reports no books and no cover for an empty serie" do
      serie = user.series.create!(name: "Bare Serie")

      previews = BookServices::IndexPreviews.for_series([ serie ])

      _(previews.book_count(serie)).must_equal 0
      _(previews.cover_book(serie)).must_be_nil
    end

    it "does not load the blobs with the cover book" do
      serie = user.series.create!(name: "Lean Serie")
      user.books.create!(filename: "lean.epub", epub_content: "x", title: "L", serie: serie, cover_bytes: "img")

      cover = BookServices::IndexPreviews.for_series([ serie ]).cover_book(serie)

      _(cover.cover?).must_equal true
      _(-> { cover.epub_content }).must_raise ActiveModel::MissingAttributeError
    end
  end

  describe ".for_authors" do
    it "counts the books and picks the first one with a cover" do
      author = user.authors.create!(name: "Preview Author")
      plain = user.books.create!(filename: "a1.epub", epub_content: "x", title: "A1")
      with_cover = user.books.create!(filename: "a2.epub", epub_content: "x", title: "A2", cover_bytes: "img")
      [ plain, with_cover ].each { |book| book.authors << author }

      previews = BookServices::IndexPreviews.for_authors([ author ])

      _(previews.book_count(author)).must_equal 2
      _(previews.cover_book(author).id).must_equal with_cover.id
    end
  end
end
