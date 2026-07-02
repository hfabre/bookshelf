require "test_helper"

describe User do
  describe "email_address normalization" do
    it "downcases and strips the email address" do
      user = User.new(email_address: "  DOWNCASED@Example.COM  ")
      _(user.email_address).must_equal "downcased@example.com"
    end
  end
end
