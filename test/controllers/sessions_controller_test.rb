require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  let(:user) { users(:one) }

  describe "GET #new" do
    it "renders the login page" do
      get new_session_url

      assert_response :success
    end
  end

  describe "POST #create" do
    it "signs in with valid credentials" do
      post session_url, params: { email_address: user.email_address, password: "password" }

      assert_redirected_to root_url
      assert cookies[:session_id].present?
    end

    it "rejects invalid credentials" do
      post session_url, params: { email_address: user.email_address, password: "wrong" }

      assert_redirected_to new_session_path
      assert_equal "Try another email address or password.", flash[:alert]
      assert_nil cookies[:session_id]
    end
  end

  describe "DELETE #destroy" do
    it "signs out" do
      sign_in_as(user)

      delete session_url

      assert_redirected_to new_session_path
      assert cookies[:session_id].blank?
    end
  end
end
