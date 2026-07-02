require "test_helper"

class I18nSmokeTest < ActionDispatch::IntegrationTest
  setup do
    Serie.rebuild_search_index
    Author.rebuild_search_index
    @admin = users(:admin)
    @one = users(:one)
    @book = @one.books.first
    @serie = @one.series.first
    @author = @one.authors.first
    # edit/merge on series & authors are admin-gated and scoped to the current
    # user's own records, so the admin needs records of their own to render them.
    @admin_serie = @admin.series.create!(name: "Admin Serie")
    @admin_author = @admin.authors.create!(name: "Admin Author")
  end

  def assert_renders(path)
    get path
    assert_response :success, "GET #{path} did not return 200"
    refute_includes @response.body, "translation missing", "translation missing on #{path}"
  end

  it "renders every page without missing translations" do
    # Unauthenticated pages
    assert_renders new_session_path
    assert_renders new_password_path

    # Admin-only pages, plus the admin-gated edit/merge screens (rendered against
    # the admin's own records).
    sign_in_as(@admin)
    assert_renders users_path
    assert_renders new_user_path
    assert_renders edit_user_path(@one)
    assert_renders edit_serie_path(@admin_serie)
    assert_renders merge_serie_path(@admin_serie)
    assert_renders edit_author_path(@admin_author)
    assert_renders merge_author_path(@admin_author)

    # Owner-scoped pages (records owned by :one).
    sign_in_as(@one)
    assert_renders books_path
    assert_renders series_path
    assert_renders authors_path
    assert_renders libraries_path
    assert_renders edit_profile_path
    assert_renders edit_book_path(@book)
    assert_renders serie_path(@serie)
    assert_renders author_path(@author)

    # Public library browsing (:one has public_library: true).
    assert_renders library_books_path(@one)
    assert_renders library_series_path(@one)
    assert_renders library_authors_path(@one)

    # Password reset edit page needs a token.
    token = @one.password_reset_token
    assert_renders edit_password_path(token)
  end

  it "renders the password reset mailer without missing translations" do
    mail = PasswordsMailer.reset(@one)
    assert_equal "Reset your password", mail.subject
    body = mail.body.encoded
    refute_includes body, "translation missing"
    assert_includes body, "this password reset page"
  end
end
