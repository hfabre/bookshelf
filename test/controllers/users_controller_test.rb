require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  before { sign_in_as(users(:admin)) }

  describe "authorization" do
    it "redirects non-admin users" do
      sign_in_as(users(:one))

      get users_url

      assert_redirected_to root_path
      assert_equal "Access denied. Admin privileges required.", flash[:alert]
    end
  end

  describe "GET #index" do
    it "renders the user list" do
      get users_url

      assert_response :success
    end
  end

  describe "GET #new" do
    it "renders the new user form" do
      get new_user_url

      assert_response :success
    end
  end

  describe "POST #create" do
    it "creates a user and redirects" do
      assert_difference -> { User.count }, 1 do
        post users_url, params: { user: { email_address: "new@example.com", password: "secret", password_confirmation: "secret" } }
      end

      assert_redirected_to users_path
      assert_equal "User was successfully created.", flash[:notice]
    end

    it "re-renders new when the confirmation does not match" do
      assert_no_difference -> { User.count } do
        post users_url, params: { user: { email_address: "bad@example.com", password: "one", password_confirmation: "two" } }
      end

      assert_response :unprocessable_entity
    end
  end

  describe "GET #edit" do
    it "renders the edit form" do
      get edit_user_url(users(:two))

      assert_response :success
    end
  end

  describe "PATCH #update" do
    it "updates the password when one is provided" do
      patch user_url(users(:two)), params: { user: { password: "newsecret", password_confirmation: "newsecret" } }

      assert_redirected_to users_path
      assert_equal "User password was successfully updated.", flash[:notice]
      assert users(:two).reload.authenticate("newsecret")
    end

    it "updates other attributes without touching the password" do
      patch user_url(users(:two)), params: { user: { admin: "1", password: "", password_confirmation: "" } }

      assert_redirected_to users_path
      assert_equal "User was successfully updated.", flash[:notice]
      _(users(:two).reload.admin?).must_equal true
      assert users(:two).authenticate("password")
    end

    it "re-renders edit when the confirmation does not match" do
      patch user_url(users(:two)), params: { user: { password: "one", password_confirmation: "two" } }

      assert_response :unprocessable_entity
    end
  end

  describe "DELETE #destroy" do
    it "deletes another user" do
      target = users(:two)

      assert_difference -> { User.count }, -1 do
        delete user_url(target)
      end

      assert_redirected_to users_path
      assert_equal "User was successfully deleted.", flash[:notice]
      _(User.exists?(target.id)).must_equal false
    end

    it "refuses to delete your own account" do
      assert_no_difference -> { User.count } do
        delete user_url(users(:admin))
      end

      assert_redirected_to users_path
      assert_equal "You cannot delete your own account.", flash[:alert]
    end
  end
end
