require "test_helper"

class DiscordNotifierTest < ActiveSupport::TestCase
  describe "#call" do
    it "is a no-op when no webhook is configured" do
      _(DiscordNotifier.new(nil).call("hi")).must_equal false
    end

    it "posts the content to the webhook" do
      posted = {}
      response = Net::HTTPOK.new("1.1", "200", "OK")

      Net::HTTP.stub(:post, ->(_uri, body, _headers) { posted[:body] = body; response }) do
        _(DiscordNotifier.new("https://discord.test/hook").call("hello")).must_equal true
      end

      _(posted[:body]).must_include "hello"
    end

    it "returns false when the request raises" do
      Net::HTTP.stub(:post, ->(*) { raise "network down" }) do
        _(DiscordNotifier.new("https://discord.test/hook").call("x")).must_equal false
      end
    end
  end
end
