require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  let(:user) { users(:one) }

  before { sign_in_as(user) }

  describe "GET #edit" do
    it "renders the profile form" do
      get edit_profile_url

      assert_response :success
    end
  end

  describe "PATCH #update" do
    it "updates settings without changing the password when it is blank" do
      patch profile_url, params: { user: { public_library: "0", password: "", password_confirmation: "" } }

      assert_redirected_to edit_profile_path
      assert_equal "Profile updated successfully.", flash[:notice]
      _(user.reload.public_library).must_equal false
      assert user.authenticate("password") # password left untouched
    end

    it "changes the password when one is provided" do
      patch profile_url, params: { user: { password: "newsecret", password_confirmation: "newsecret" } }

      assert_redirected_to edit_profile_path
      assert user.reload.authenticate("newsecret")
    end

    it "re-renders edit when the password confirmation does not match" do
      patch profile_url, params: { user: { password: "one", password_confirmation: "two" } }

      assert_response :unprocessable_entity
    end
  end
end
