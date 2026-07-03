require "test_helper"

class MissionControlAuthTest < ActionDispatch::IntegrationTest
  it "redirects to login instead of raising when Mission Control is accessed unauthenticated" do
    get "/jobs"

    assert_redirected_to "/session/new"
  end
end
