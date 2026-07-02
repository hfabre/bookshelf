require "test_helper"

class BookServices::UpdateAndSyncTest < ActiveSupport::TestCase
  let(:book) { books(:merged_book_one) }

  it "updates the book, its serie and authors, then syncs to the epub" do
    sync = Minitest::Mock.new
    sync.expect(:call, nil)

    result = BookServices::SyncToEpub.stub(:new, ->(*) { sync }) do
      BookServices::UpdateAndSync.new(book, users(:one)).call(
        title: "New Title",
        language: "fr",
        serie_name: "New Serie",
        author_names: [ "Author One", " Author Two " ]
      )
    end

    _(result).must_equal true
    assert_mock sync

    book.reload
    _(book.title).must_equal "New Title"
    _(book.language).must_equal "fr"
    _(book.serie.name).must_equal "New Serie"
    _(book.serie.user).must_equal users(:one)
    _(book.authors.map(&:name).sort).must_equal [ "Author One", "Author Two" ]
    _(book.authors.map(&:user).uniq).must_equal [ users(:one) ]
  end

  it "names the serie after the book title when no serie_name is given" do
    sync = Minitest::Mock.new
    sync.expect(:call, nil)

    BookServices::SyncToEpub.stub(:new, ->(*) { sync }) do
      BookServices::UpdateAndSync.new(book, users(:one)).call(title: "Standalone", author_names: [])
    end

    _(book.reload.serie.name).must_equal "Standalone"
  end

  it "stores an uploaded cover using its content type" do
    sync = Minitest::Mock.new
    sync.expect(:call, nil)
    cover = fixture_file_upload("new_cover.png", "image/png")

    BookServices::SyncToEpub.stub(:new, ->(*) { sync }) do
      BookServices::UpdateAndSync.new(book, users(:one)).call(title: "T", cover: cover)
    end

    book.reload
    _(book.cover_bytes).must_equal file_fixture("new_cover.png").binread
    _(book.cover_type).must_equal "image/png"
  end

  it "returns false and does not sync when the book is invalid" do
    result = BookServices::SyncToEpub.stub(:new, ->(*) { flunk "should not sync an invalid book" }) do
      BookServices::UpdateAndSync.new(book, users(:one)).call(title: "T", filename: "")
    end

    _(result).must_equal false
    _(book.reload.filename).must_equal "merged_one.epub"
  end
end
