SolidQueue.on_thread_error = ->(error) do
  Rails.logger.error("[SolidQueue thread died] #{error.class}: #{error.message}\n#{error.backtrace&.join("\n")}")
end
