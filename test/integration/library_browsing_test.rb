require "test_helper"

# Browsing a library is the ordinary browse pages scoped to its owner, so it
# spans the books, series and authors controllers rather than one of them.
class LibraryBrowsingTest < ActionDispatch::IntegrationTest
  let(:viewer) { users(:two) }
  let(:owner) { users(:one) } # public_library: true
  let(:private_owner) { users(:admin) }

  before { sign_in_as(viewer) }

  describe "a public library" do
    it "renders its books, series and authors" do
      [ library_books_url(owner), library_series_url(owner), library_authors_url(owner) ].each do |url|
        get url

        assert_response :success
      end
    end

    it "renders a single serie and author from it" do
      get library_serie_url(owner, series(:target))
      assert_response :success

      get library_author_url(owner, authors(:tolkien))
      assert_response :success
    end

    it "lists the owner's records rather than the viewer's" do
      get library_series_url(owner)

      _(response.body).must_include series(:target).name
      _(response.body).wont_include series(:other_user).name # the viewer's own serie
    end

    it "can be browsed as your own library even when it is not public" do
      get library_books_url(viewer)

      assert_response :success
    end
  end

  describe "a library that is not public" do
    it "is refused on every browse page" do
      [ library_books_url(private_owner), library_series_url(private_owner), library_authors_url(private_owner) ].each do |url|
        get url

        assert_redirected_to root_path
        assert_equal "This library is not public.", flash[:alert]
      end
    end

    it "is refused for a single serie" do
      get library_serie_url(private_owner, series(:admin_serie))

      assert_redirected_to root_path
      assert_equal "This library is not public.", flash[:alert]
    end
  end

  # Reading a library includes taking the files out of it.
  describe "downloading from a library you may read" do
    it "sends a book from a public library" do
      get download_book_url(books(:merged_book_one))

      assert_response :success
      assert_equal "application/epub+zip", response.media_type
    end

    it "sends a serie's books from a public library" do
      get download_serie_url(series(:to_merge))

      assert_response :success
      assert_equal "application/zip", response.media_type
    end

    it "sends an author's books from a public library" do
      get download_author_url(authors(:tolkien))

      assert_response :success
      assert_equal "application/zip", response.media_type
    end

    it "refuses everything in a library that is not public" do
      sign_in_as(owner) # the viewer's own library is private

      get download_book_url(books(:failed_book))
      assert_response :not_found

      get download_serie_url(series(:other_user))
      assert_response :not_found

      get download_author_url(authors(:brandon_other_user))
      assert_response :not_found
    end
  end

  # :user_id scopes reading wherever it is passed, since params does not care
  # whether it came from the path, and the same check runs either way.
  describe "the user_id param" do
    it "reads a public library from a query string as well as from the path" do
      get series_url(user_id: owner.id)

      _(response.body).must_include series(:target).name     # the owner's
      _(response.body).wont_include series(:other_user).name # the viewer's own
    end

    it "still refuses a library that is not public" do
      get series_url(user_id: private_owner.id)

      assert_redirected_to root_path
      assert_equal "This library is not public.", flash[:alert]
    end

    it "never bundles another library into download all" do
      sign_in_as(users(:admin)) # owns no books

      get download_all_series_url(user_id: owner.id)

      assert_redirected_to series_path
      assert_equal "You don't have any books to download yet.", flash[:alert]
    end

    it "does not hand over another user's serie to edit" do
      sign_in_as(users(:admin))

      get edit_serie_url(series(:target), user_id: owner.id)

      assert_response :not_found
    end

    it "does not hand over another user's serie to merge" do
      get merge_serie_url(series(:target), user_id: owner.id)

      assert_response :not_found
    end
  end
end
