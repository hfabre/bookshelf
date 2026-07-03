require "test_helper"

class BookServices::SyncFromEpubTest < ActiveSupport::TestCase
  let(:book) { books(:with_authors) }

  it "maps the epub metadata onto the book" do
    sync book, metadata: {
      title: "The Left Hand of Darkness",
      authors: [ "Ursula K. Le Guin" ],
      description: "A description",
      language: "en",
      date: "1969-03-01",
      publisher: "Ace Books",
      serie: "Hainish Cycle",
      serie_index: "4",
      cover_path: "cover.png"
    }, cover_bytes: "PNGDATA"

    book.reload
    _(book.title).must_equal "The Left Hand of Darkness"
    _(book.description).must_equal "A description"
    _(book.language).must_equal "en"
    _(book.date).must_equal Date.new(1969, 3, 1)
    _(book.publisher).must_equal "Ace Books"
    _(book.serie_index).must_equal 4
    _(book.cover_bytes).must_equal "PNGDATA"

    _(book.serie.name).must_equal "Hainish Cycle"
    _(book.serie.user).must_equal users(:one)
    _(book.author_names).must_equal "Ursula K. Le Guin"
    _(book.authors.first.user).must_equal users(:one)
  end

  it "falls back to the filename for the title and names the serie after it" do
    sync book, metadata: { title: "", authors: [], serie: "", cover_path: "cover.jpg" }

    book.reload
    _(book.title).must_equal "with_authors"
    _(book.serie.name).must_equal "with_authors"
  end

  it "reuses an existing author instead of creating a duplicate" do
    sync book, metadata: { title: "T", authors: [ "J.R.R. Tolkien" ], serie: "S", cover_path: "cover.jpg" }

    _(book.reload.authors.to_a).must_equal [ authors(:tolkien) ]
    _(users(:one).authors.where(name: "J.R.R. Tolkien").count).must_equal 1
  end

  it "recovers when a concurrent job already created the author" do
    raised = false
    original = users(:one).authors.method(:find_or_create_by!)
    users(:one).authors.stub(:find_or_create_by!, ->(attrs) {
      unless raised
        raised = true
        users(:one).authors.create!(name: "Race Author")
        raise ActiveRecord::RecordInvalid
      end
      original.call(attrs)
    }) do
      sync book, metadata: { title: "T", authors: [ "Race Author" ], serie: "S", cover_path: "cover.jpg" }
    end

    _(book.reload.author_names).must_equal "Race Author"
    _(users(:one).authors.where(name: "Race Author").count).must_equal 1
  end

  it "leaves the date nil when the epub date is unparseable" do
    sync book, metadata: { title: "T", authors: [], serie: "S", date: "not-a-date", cover_path: "cover.jpg" }

    _(book.reload.date).must_be_nil
  end

  it "handles an epub without a cover" do
    sync book, metadata: { title: "T", authors: [], serie: "S" }, cover_bytes: nil

    book.reload
    _(book.cover_bytes).must_be_nil
    _(book.cover_type).must_be_nil
  end

  private

  def sync(book, metadata:, cover_bytes: "COVER")
    epub = Minitest::Mock.new
    epub.expect(:mt_hash, metadata)
    epub.expect(:cover_bytes, cover_bytes)

    book.stub(:epub, epub) do
      BookServices::SyncFromEpub.new(book, users(:one)).call
    end
  end
end
