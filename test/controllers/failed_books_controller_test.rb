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
end
