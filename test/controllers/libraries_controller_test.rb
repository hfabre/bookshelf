require "test_helper"

# Browsing the libraries themselves lives in test/integration/library_browsing_test.rb
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

    it "redirects away from a library that is not public" do
      get library_url(users(:admin))

      assert_redirected_to root_path
      assert_equal "This library is not public.", flash[:alert]
    end
  end
end
