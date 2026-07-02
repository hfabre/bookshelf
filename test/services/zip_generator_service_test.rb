require "test_helper"

class ZipGeneratorServiceTest < ActiveSupport::TestCase
  subject { ZipGeneratorService.new }

  describe "#call" do
    it "fails when there are no books" do
      result = subject.call([], "My Serie")

      _(result[:success]).must_equal false
      _(result[:error]).must_equal "No books found"
    end

    it "builds a zip named after the parameterized prefix" do
      result = subject.call([ books(:merged_book_one) ], "My Great Serie!")

      _(result[:success]).must_equal true
      _(result[:filename]).must_equal "my-great-serie-books.zip"
      _(result[:zip_data]).wont_be_empty
    end

    it "writes one entry per book, using the filename and epub content" do
      result = subject.call([ books(:merged_book_one), books(:merged_book_two) ], "Serie")

      entries = read_zip(result[:zip_data])

      _(entries.keys.sort).must_equal [ "merged_one.epub", "merged_two.epub" ]
      _(entries["merged_one.epub"]).must_equal "epub-bytes"
    end

    it "skips books without epub content" do
      empty = Book.new(filename: "empty.epub", epub_content: nil)
      result = subject.call([ books(:merged_book_one), empty ], "Serie")

      _(read_zip(result[:zip_data]).keys).must_equal [ "merged_one.epub" ]
    end
  end

  private

  def read_zip(data)
    {}.tap do |entries|
      Zip::InputStream.open(StringIO.new(data)) do |io|
        while (entry = io.get_next_entry)
          entries[entry.name] = io.read
        end
      end
    end
  end
end
