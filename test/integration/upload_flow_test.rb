require "test_helper"

# End-to-end upload with nothing stubbed, so a dependency bump that breaks
# EPUB processing (rubyzip, nokogiri, Active Job...) fails here.
class UploadFlowTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  let(:user) { users(:one) }

  before { sign_in_as(user) }

  it "turns an uploaded epub into a completed book with its metadata" do
    perform_enqueued_jobs do
      post upload_books_url, params: { files: [ fixture_file_upload("valid.epub", "application/epub+zip") ] }
    end

    assert_redirected_to books_url

    book = user.books.find_by!(filename: "valid.epub")
    _(book.processing_status).must_equal "completed"
    _(book.title).must_equal "Légendes espagnoles"
    _(book.author_names).must_equal "Gustavo-Adolfo Bécquer"

    get edit_book_url(book)
    assert_response :success
  end
end
