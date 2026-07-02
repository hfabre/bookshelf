require "test_helper"

class BookServices::SyncToEpubTest < ActiveSupport::TestCase
  it "writes the book metadata and cover into the epub, then persists the buffer" do
    book = books(:with_authors)
    book.update_columns(title: "Synced Title", cover_bytes: "COVER", cover_type: "image/png")

    epub = Minitest::Mock.new
    epub.expect(:update_mt!, nil) do |metadata|
      metadata[:title] == "Synced Title" &&
        metadata[:series_index] == book.serie_index &&
        metadata[:authors] == book.author_names &&
        metadata[:serie] == book.serie&.name
    end
    epub.expect(:replace_cover!, nil) { |path| File.binread(path) == "COVER" }
    epub.expect(:current_buffer, StringIO.new("NEW EPUB BYTES"))

    book.stub(:epub, epub) do
      BookServices::SyncToEpub.new(book).call
    end

    assert_mock epub
    _(book.reload.epub_content).must_equal "NEW EPUB BYTES"
  end
end
