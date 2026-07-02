require "test_helper"

class EpubProcessorJobTest < ActiveSupport::TestCase
  let(:user) { users(:one) }
  let(:book) { books(:with_authors) }

  describe "#perform" do
    it "marks the book completed on success" do
      sync = Minitest::Mock.new
      sync.expect(:call, true)

      BookServices::SyncFromEpub.stub(:new, ->(*) { sync }) do
        EpubProcessorJob.new.perform(book.id, user.id)
      end

      assert_mock sync
      _(book.reload.processing_status).must_equal "completed"
    end

    it "records the failure message and re-raises on error" do
      BookServices::SyncFromEpub.stub(:new, ->(*) { raise "boom" }) do
        assert_raises(RuntimeError) { EpubProcessorJob.new.perform(book.id, user.id) }
      end

      book.reload
      _(book.processing_status).must_equal "failed"
      _(book.failure_message).must_equal "boom"
    end
  end
end
