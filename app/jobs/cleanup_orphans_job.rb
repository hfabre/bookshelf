class CleanupOrphansJob < ApplicationJob
  queue_as :default

  def perform
    result = BookServices::CleanupOrphans.sweep
    Rails.logger.info "CleanupOrphansJob removed #{result[:series]} empty series and #{result[:authors]} empty authors"
  end
end
