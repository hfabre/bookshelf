require "test_helper"

class AuthorsControllerTest < ActionDispatch::IntegrationTest
  let(:user) { users(:one) }
  let(:author) { authors(:merge_target) }

  before { sign_in_as(user) }

  describe "GET #index" do
    it "renders the author list" do
      get authors_url

      assert_response :success
    end

    it "returns the filtered authors as json" do
      get authors_url(format: :json, q: "Sanderson")

      names = JSON.parse(response.body).map { |a| a["name"] }
      _(names).must_equal [ "Brandon Sanderson" ]
    end
  end

  describe "GET #show" do
    it "renders the author" do
      get author_url(authors(:merge_source))

      assert_response :success
    end
  end

  describe "GET #edit" do
    it "is blocked for non-admin users" do
      get edit_author_url(author)

      assert_redirected_to root_path
      assert_equal "Access denied.", flash[:alert]
    end

    it "renders for an admin" do
      sign_in_as(users(:admin))

      get edit_author_url(authors(:admin_author))

      assert_response :success
    end
  end

  describe "PATCH #update" do
    it "updates the author and redirects for an admin" do
      sign_in_as(users(:admin))

      patch author_url(authors(:admin_author)), params: { author: { name: "Renamed" } }

      assert_redirected_to author_path(authors(:admin_author))
      assert_equal "Author was successfully updated.", flash[:notice]
      _(authors(:admin_author).reload.name).must_equal "Renamed"
    end

    it "re-renders edit for an admin when the update is invalid" do
      sign_in_as(users(:admin))

      patch author_url(authors(:admin_author)), params: { author: { name: "" } }

      assert_response :unprocessable_entity
      _(authors(:admin_author).reload.name).must_equal "Admin Owned Author"
    end

    it "is blocked for non-admin users" do
      patch author_url(author), params: { author: { name: "Renamed" } }

      assert_redirected_to root_path
      assert_equal "Access denied.", flash[:alert]
      _(author.reload.name).wont_equal "Renamed"
    end
  end

  describe "GET #merge" do
    it "renders the merge page" do
      get merge_author_url(author)

      assert_response :success
    end
  end

  describe "GET #download" do
    it "sends a zip of the author's books" do
      get download_author_url(authors(:merge_source))

      assert_response :success
      assert_equal "application/zip", response.media_type
    end

    it "redirects with an alert when the author has no books" do
      get download_author_url(authors(:sanderson))

      assert_redirected_to author_path(authors(:sanderson))
      assert_equal "No books found", flash[:alert]
    end
  end

  describe "POST #perform_merge" do
    it "hands the selected authors to the merge service and redirects on success" do
      to_merge = authors(:merge_source)
      service = Minitest::Mock.new
      service.expect(:call, { success: true, message: "Merged!" }) do |selected|
        selected.pluck(:id) == [ to_merge.id ]
      end

      AuthorServices::MergeService.stub(:new, ->(*) { service }) do
        post perform_merge_author_url(author), params: { author_ids: [ to_merge.id ] }
      end

      assert_mock service
      assert_redirected_to authors_path
      assert_equal "Merged!", flash[:notice]
    end

    it "redirects back to the merge page with the service error on failure" do
      service = Minitest::Mock.new
      service.expect(:call, { success: false, error: "Boom" }) { true }

      AuthorServices::MergeService.stub(:new, ->(*) { service }) do
        post perform_merge_author_url(author), params: { author_ids: [ authors(:merge_source).id ] }
      end

      assert_mock service
      assert_redirected_to merge_author_path(author)
      assert_equal "Boom", flash[:alert]
    end

    it "skips the service and redirects back when no authors are selected" do
      AuthorServices::MergeService.stub(:new, ->(*) { flunk "service should not be called" }) do
        post perform_merge_author_url(author), params: { author_ids: [] }
      end

      assert_redirected_to merge_author_path(author)
      assert_equal "No authors selected for merging.", flash[:alert]
    end
  end
end
