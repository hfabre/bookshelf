require "test_helper"

class BookServices::CreateFromUploadsTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  let(:user) { users(:one) }

  it "creates a pending book and enqueues processing for each epub" do
    files = [
      fixture_file_upload("valid.epub", "application/epub+zip"),
      fixture_file_upload("calibre_serie.epub", "application/epub+zip")
    ]

    result = nil
    assert_difference -> { user.books.count }, 2 do
      assert_enqueued_jobs 2, only: EpubProcessorJob do
        result = BookServices::CreateFromUploads.new(user).call(files)
      end
    end

    _(result[:created]).must_equal 2
    _(result[:skipped]).must_be_empty

    book = user.books.find_by(filename: "valid.epub")
    _(book.title).must_equal "valid"
    _(book.processing_status).must_equal "pending"
    _(book.job_id).must_equal enqueued_jobs.find { |j| j["arguments"].first == book.id }["job_id"]
  end

  it "accepts an epub by extension even when the content type is generic" do
    file = fixture_file_upload("valid.epub", "application/octet-stream")

    assert_difference -> { user.books.count }, 1 do
      _(BookServices::CreateFromUploads.new(user).call([ file ])[:created]).must_equal 1
    end
  end

  it "rejects a file whose content isn't a zip, even with an .epub name and spoofed content type" do
    file = fixture_file_upload("fake.epub", "application/epub+zip")

    assert_no_difference -> { user.books.count } do
      assert_no_enqueued_jobs do
        _(BookServices::CreateFromUploads.new(user).call([ file ])[:created]).must_equal 0
      end
    end
  end

  it "ignores non-epub files, blanks and stray strings" do
    file = fixture_file_upload("new_cover.png", "image/png")

    assert_no_difference -> { user.books.count } do
      assert_no_enqueued_jobs do
        _(BookServices::CreateFromUploads.new(user).call([ file, nil, "", "not-a-file" ])[:created]).must_equal 0
      end
    end
  end

  it "skips a file whose filename is already in the library without crashing" do
    user.books.create!(filename: "valid.epub", epub_content: "x", title: "existing")
    file = fixture_file_upload("valid.epub", "application/epub+zip")

    result = nil
    assert_no_difference -> { user.books.count } do
      assert_no_enqueued_jobs do
        result = BookServices::CreateFromUploads.new(user).call([ file ])
      end
    end

    _(result[:created]).must_equal 0
    _(result[:skipped]).must_equal [ "valid.epub" ]
  end
end
