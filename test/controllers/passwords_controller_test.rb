require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  let(:user) { users(:one) }

  describe "GET #new" do
    it "renders the request form" do
      get new_password_url

      assert_response :success
    end
  end

  describe "POST #create" do
    it "emails reset instructions for a known address" do
      assert_enqueued_email_with PasswordsMailer, :reset, args: [ user ] do
        post passwords_url, params: { email_address: user.email_address }
      end

      assert_redirected_to new_session_path
    end

    it "does not email an unknown address but still redirects" do
      assert_no_enqueued_emails do
        post passwords_url, params: { email_address: "nobody@example.com" }
      end

      assert_redirected_to new_session_path
    end
  end

  describe "GET #edit" do
    it "renders for a valid token" do
      get edit_password_url(user.password_reset_token)

      assert_response :success
    end

    it "redirects for an invalid token" do
      get edit_password_url("invalid")

      assert_redirected_to new_password_path
      assert_equal "Password reset link is invalid or has expired.", flash[:alert]
    end
  end

  describe "PATCH #update" do
    it "resets the password with matching confirmation" do
      put password_url(user.password_reset_token),
          params: { password: "newsecret", password_confirmation: "newsecret" }

      assert_redirected_to new_session_path
      assert_equal "Password has been reset.", flash[:notice]
      assert user.reload.authenticate("newsecret")
    end

    it "redirects back when the passwords do not match" do
      token = user.password_reset_token

      put password_url(token), params: { password: "one", password_confirmation: "two" }

      assert_redirected_to edit_password_path(token)
      assert_equal "Passwords did not match.", flash[:alert]
    end
  end
end
