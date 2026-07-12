require "test_helper"

class BookServices::HandleProcessingFailureTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  let(:book) { books(:with_authors) }
  let(:error) { RuntimeError.new("boom") }
  subject { BookServices::HandleProcessingFailure.new(book) }

  describe "#call" do
    it "marks the book failed and records the reason" do
      subject.call(error)

      book.reload
      _(book.processing_status).must_equal "failed"
      _(book.failure_message).must_equal "boom"
    end

    it "emails the uploader" do
      assert_enqueued_email_with EpubProcessingMailer, :failed, args: [ book ] do
        subject.call(error)
      end
    end

    it "notifies discord with the failure reason" do
      notifier = Minitest::Mock.new
      notifier.expect(:call, true) { |msg| msg.include?("boom") }

      DiscordNotifier.stub(:new, ->(*) { notifier }) do
        subject.call(error)
      end

      assert_mock notifier
    end
  end
end
