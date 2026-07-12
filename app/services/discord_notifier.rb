require "net/http"

class DiscordNotifier
  def initialize(webhook_url = ENV["DISCORD_WEBHOOK_URL"])
    @webhook_url = webhook_url
  end

  def call(content)
    return false if @webhook_url.blank?

    response = Net::HTTP.post(
      URI(@webhook_url),
      { content: content }.to_json,
      "Content-Type" => "application/json"
    )
    response.is_a?(Net::HTTPSuccess)
  rescue => e
    Rails.logger.error "DiscordNotifier failed: #{e.message}"
    false
  end
end
