require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  let(:user) { users(:one) }

  before { sign_in_as(user) }

  describe "GET #index" do
    it "renders the book list" do
      get books_url

      assert_response :success
    end

    it "filters by title" do
      books(:with_authors).update_column(:title, "Findable Title")
      books(:merged_book_one).update_column(:title, "Hidden Title")

      get books_url(q: "Findable")

      assert_includes response.body, "Findable Title"
      assert_not_includes response.body, "Hidden Title"
    end

    it "filters books without a series" do
      books(:with_authors).update_column(:title, "No Serie Book")
      books(:merged_book_one).update_column(:title, "Has Serie Book")

      get books_url(filter: "no_serie")

      assert_includes response.body, "No Serie Book"
      assert_not_includes response.body, "Has Serie Book"
    end

    it "filters books without an author" do
      books(:merged_book_one).update_column(:title, "No Author Book")
      books(:with_authors).update_column(:title, "Has Author Book")

      get books_url(filter: "no_author")

      assert_includes response.body, "No Author Book"
      assert_not_includes response.body, "Has Author Book"
    end

    it "filters books missing a series or an author" do
      books(:with_authors).update_column(:title, "Missing Serie Book")
      books(:merged_book_one).update_column(:title, "Missing Author Book")
      user.books.create!(
        filename: "complete.epub", epub_content: "bytes",
        serie: series(:to_merge), serie_index: 99, authors: [ authors(:tolkien) ], title: "Complete Book"
      )

      get books_url(filter: "incomplete")

      assert_includes response.body, "Missing Serie Book"
      assert_includes response.body, "Missing Author Book"
      assert_not_includes response.body, "Complete Book"
    end
  end

  describe "GET #edit" do
    it "renders the edit form" do
      get edit_book_url(books(:with_authors))

      assert_response :success
    end
  end

  describe "PATCH #update" do
    it "syncs the book and redirects on success" do
      service = Minitest::Mock.new
      service.expect(:call, true) { true }

      BookServices::UpdateAndSync.stub(:new, ->(*) { service }) do
        patch book_url(books(:with_authors)), params: { book: { title: "New" } }
      end

      assert_mock service
      assert_redirected_to books_path
      assert_equal "Book was successfully updated.", flash[:notice]
    end

    it "re-renders edit when the sync fails" do
      service = Minitest::Mock.new
      service.expect(:call, false) { true }

      BookServices::UpdateAndSync.stub(:new, ->(*) { service }) do
        patch book_url(books(:with_authors)), params: { book: { title: "" } }
      end

      assert_mock service
      assert_response :unprocessable_entity
    end
  end

  describe "DELETE #destroy" do
    it "deletes the book and redirects" do
      book = books(:with_authors)

      delete book_url(book)

      assert_redirected_to books_path
      assert_equal "Book was successfully deleted.", flash[:notice]
      _(Book.exists?(book.id)).must_equal false
    end
  end

  describe "GET #download" do
    it "sends the epub file" do
      get download_book_url(books(:merged_book_one))

      assert_response :success
      assert_equal "application/epub+zip", response.media_type
      _(response.body).must_equal "epub-bytes"
    end
  end

  describe "POST #upload" do
    it "calls the service and reports how many books were created" do
      service = Minitest::Mock.new
      service.expect(:call, 1) { true }

      BookServices::CreateFromUploads.stub(:new, ->(*) { service }) do
        post upload_books_url, params: { files: [ fixture_file_upload("valid.epub", "application/epub+zip") ] }
      end

      assert_mock service
      assert_redirected_to books_path
      assert_equal "1 EPUB file(s) uploaded and are being processed.", flash[:notice]
    end

    it "alerts when the service creates no books" do
      service = Minitest::Mock.new
      service.expect(:call, 0) { true }

      BookServices::CreateFromUploads.stub(:new, ->(*) { service }) do
        post upload_books_url, params: { files: [ fixture_file_upload("new_cover.png", "image/png") ] }
      end

      assert_mock service
      assert_redirected_to books_path
      assert_equal "No valid EPUB files were found.", flash[:alert]
    end

    it "redirects with an alert when no files are given" do
      post upload_books_url, params: {}

      assert_redirected_to books_path
      assert_equal "Please select at least one EPUB file.", flash[:alert]
    end
  end
end
