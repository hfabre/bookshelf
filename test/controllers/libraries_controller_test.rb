require "test_helper"

class LibrariesControllerTest < ActionDispatch::IntegrationTest
  let(:viewer) { users(:two) }
  let(:owner) { users(:one) } # public_library: true

  before { sign_in_as(viewer) }

  describe "GET #index" do
    it "lists public libraries" do
      get libraries_url

      assert_response :success
    end
  end

  describe "GET #show" do
    it "redirects to the library's books" do
      get library_url(owner)

      assert_redirected_to library_books_path(owner)
    end
  end

  describe "GET #books" do
    it "renders the public library's books" do
      get library_books_url(owner)

      assert_response :success
    end
  end

  describe "GET #series" do
    it "renders the public library's series" do
      get library_series_url(owner)

      assert_response :success
    end
  end

  describe "GET #authors" do
    it "renders the public library's authors" do
      get library_authors_url(owner)

      assert_response :success
    end
  end

  describe "GET #show_serie" do
    it "renders a serie from the public library" do
      get library_serie_url(owner, series(:target))

      assert_response :success
    end
  end

  describe "GET #show_author" do
    it "renders an author from the public library" do
      get library_author_url(owner, authors(:tolkien))

      assert_response :success
    end
  end

  describe "access control" do
    it "redirects when the library is not public" do
      get library_books_url(users(:admin))

      assert_redirected_to root_path
      assert_equal "This library is not public.", flash[:alert]
    end

    it "allows browsing your own library even when not public" do
      get library_books_url(viewer)

      assert_response :success
    end
  end
end
