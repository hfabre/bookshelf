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

  it "skips blank and nil author names" do
    sync book, metadata: { title: "T", authors: [ "Real Author", "", nil, "   " ], serie: "S", cover_path: "cover.jpg" }

    _(book.reload.author_names).must_equal "Real Author"
  end

  it "deduplicates repeated author names instead of failing the join insert" do
    sync book, metadata: { title: "T", authors: [ "Same Author", "Same Author" ], serie: "S", cover_path: "cover.jpg" }

    _(book.reload.authors.count).must_equal 1
  end

  it "leaves serie_index unset when it collides with another book in the serie" do
    serie = users(:one).series.create!(name: "Collide Serie")
    users(:one).books.create!(filename: "other.epub", epub_content: "x", title: "Other", serie: serie, serie_index: 3)

    sync book, metadata: { title: "T", authors: [], serie: "Collide Serie", serie_index: "3", cover_path: "cover.jpg" }

    book.reload
    _(book.serie.name).must_equal "Collide Serie"
    _(book.serie_index).must_be_nil
  end

  it "keeps a non-colliding serie_index" do
    sync book, metadata: { title: "T", authors: [], serie: "Fresh Serie", serie_index: "5", cover_path: "cover.jpg" }

    _(book.reload.serie_index).must_equal 5
  end

  it "does not swallow unrelated save errors as a serie_index conflict" do
    # A filename clash is not a serie_index conflict and must surface.
    users(:one).books.create!(filename: "taken.epub", epub_content: "x", title: "Taken")
    book.filename = "taken.epub"

    _(-> { sync book, metadata: { title: "T", authors: [], serie: "S", cover_path: "cover.jpg" } })
      .must_raise ActiveRecord::RecordInvalid
  end

  it "repairs and persists an archive wrapped in a top-level directory" do
    wrapped = wrap_epub(file_fixture("valid.epub").to_s, "Some Book Dir/")
    book = users(:one).books.create!(filename: "wrapped.epub", epub_content: wrapped, title: "tmp")

    BookServices::SyncFromEpub.new(book, users(:one)).call

    book.reload
    _(book.title).must_equal "Légendes espagnoles"
    _(book.cover_bytes).wont_be_nil
    # the stored archive now loads without needing further repair
    _(BsEpub::Epub.new(book.epub_content).failure_reason).must_be_nil
  end

  private

  def wrap_epub(source_path, prefix)
    Zip::OutputStream.write_buffer do |out|
      Zip::File.open(source_path) do |zip|
        zip.each do |entry|
          next if entry.directory?

          out.put_next_entry(prefix + entry.name)
          out.write(entry.get_input_stream.read)
        end
      end
    end.string
  end

  def sync(book, metadata:, cover_bytes: "COVER")
    epub = Minitest::Mock.new
    epub.expect(:failure_reason, nil)
    epub.expect(:mt_hash, metadata)
    epub.expect(:cover_bytes, cover_bytes)

    book.stub(:epub, epub) do
      BookServices::SyncFromEpub.new(book, users(:one)).call
    end
  end
end
