require "test_helper"

describe Book do
  describe "validations" do
    let(:book) { Book.new(filename: "x.epub", epub_content: "bytes", user: users(:one)) }

    it "is valid with a filename, epub content and user" do
      _(book).must_be :valid?
    end

    it "requires a filename" do
      book.filename = nil
      _(book).wont_be :valid?
      _(book.errors[:filename]).must_include "can't be blank"
    end

    it "requires epub content" do
      book.epub_content = nil
      _(book).wont_be :valid?
      _(book.errors[:epub_content]).must_include "can't be blank"
    end

    it "scopes filename uniqueness to the user" do
      existing = books(:merged_book_one)

      duplicate = Book.new(filename: existing.filename, epub_content: "bytes", user: existing.user)
      _(duplicate).wont_be :valid?
      _(duplicate.errors[:filename]).must_include "has already been taken"

      other_user = Book.new(filename: existing.filename, epub_content: "bytes", user: users(:two))
      _(other_user).must_be :valid?
    end

    it "rejects a duplicate serie_index within the same serie" do
      existing = books(:merged_book_one) # serie to_merge, index 1

      duplicate = books(:merged_book_two) # serie to_merge, index 2
      duplicate.serie_index = existing.serie_index
      _(duplicate).wont_be :valid?
      _(duplicate.errors[:serie_index]).must_include "has already been taken"
    end

    it "allows a duplicate serie_index across different series and blank indexes" do
      other_serie = Book.new(filename: "z.epub", epub_content: "bytes", user: users(:one),
                             serie: series(:target), serie_index: 1)
      _(other_serie).must_be :valid?

      no_index = Book.new(filename: "w.epub", epub_content: "bytes", user: users(:one),
                          serie: series(:to_merge), serie_index: nil)
      _(no_index).must_be :valid?
    end
  end

  describe "#cover?" do
    it "is true only when cover bytes are present" do
      _(Book.new(cover_bytes: "data").cover?).must_equal true
      _(Book.new(cover_bytes: nil).cover?).must_equal false
    end
  end

  describe "#cover_mime_type" do
    it "falls back to image/jpeg when no cover type is set" do
      _(Book.new(cover_type: "image/png").cover_mime_type).must_equal "image/png"
      _(Book.new(cover_type: nil).cover_mime_type).must_equal "image/jpeg"
    end
  end

  describe ".without_blobs" do
    it "leaves out the blobs and still answers cover?" do
      book = books(:with_authors)
      book.update_columns(cover_bytes: "img", cover_type: "image/png")

      lean = Book.without_blobs.find(book.id)

      _(lean.cover?).must_equal true
      _(-> { lean.epub_content }).must_raise ActiveModel::MissingAttributeError
      _(-> { lean.cover_bytes }).must_raise ActiveModel::MissingAttributeError
    end

    it "answers cover? without a cover" do
      _(Book.without_blobs.find(books(:merged_book_one).id).cover?).must_equal false
    end
  end

  describe "#author_names" do
    it "joins the author names with a comma" do
      names = books(:with_authors).author_names.split(", ")
      _(names.sort).must_equal [ "C.S. Lewis", "J.R.R. Tolkien" ]
    end
  end
end
