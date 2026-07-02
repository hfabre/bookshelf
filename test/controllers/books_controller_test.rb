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
    it "creates a book and enqueues processing for a valid epub" do
      file = fixture_file_upload("valid.epub", "application/epub+zip")

      assert_difference -> { user.books.count }, 1 do
        assert_enqueued_with(job: EpubProcessorJob) do
          post upload_books_url, params: { files: [ file ] }
        end
      end

      assert_redirected_to books_path
      assert_equal "1 EPUB file(s) uploaded and are being processed.", flash[:notice]
    end

    it "rejects files that are not epubs" do
      file = fixture_file_upload("new_cover.png", "image/png")

      assert_no_difference -> { user.books.count } do
        post upload_books_url, params: { files: [ file ] }
      end

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
