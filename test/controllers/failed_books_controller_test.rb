require "test_helper"

class FailedBooksControllerTest < ActionDispatch::IntegrationTest
  before { sign_in_as(users(:admin)) }

  describe "authorization" do
    it "redirects non-admin users" do
      sign_in_as(users(:one))

      get failed_books_url

      assert_redirected_to root_path
    end
  end

  describe "GET #index" do
    it "lists failed books across all users with a job link" do
      get failed_books_url

      assert_response :success
      assert_includes response.body, "broken.epub"
      assert_includes response.body, "Nokogiri::XML::SyntaxError: bad opf"
      assert_includes response.body, "/jobs/applications/bookshelf/jobs/11111111-2222-3333-4444-555555555555"
    end

    it "does not list books that processed successfully" do
      get failed_books_url

      assert_not_includes response.body, "shared_book.epub"
    end
  end

  describe "GET #download" do
    it "sends the original epub of another user's failed book" do
      get download_failed_book_url(books(:failed_book))

      assert_response :success
      assert_equal "application/epub+zip", response.media_type
      _(response.body).must_equal "epub-bytes"
    end
  end

  describe "DELETE #destroy" do
    it "clears a single failed book" do
      book = books(:failed_book)

      delete failed_book_url(book)

      assert_redirected_to failed_books_path
      _(Book.exists?(book.id)).must_equal false
    end

    it "does not clear a book that has not failed" do
      delete failed_book_url(books(:shared_book))

      assert_response :not_found
      _(Book.exists?(books(:shared_book).id)).must_equal true
    end
  end

  describe "DELETE #clear_all" do
    it "clears every failed book but leaves processed ones" do
      delete clear_all_failed_books_url

      assert_redirected_to failed_books_path
      _(Book.failed.count).must_equal 0
      _(Book.exists?(books(:shared_book).id)).must_equal true
    end
  end
end
