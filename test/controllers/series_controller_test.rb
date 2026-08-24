require "test_helper"

class SeriesControllerTest < ActionDispatch::IntegrationTest
  let(:user) { users(:one) }
  let(:serie) { series(:target) }

  before { sign_in_as(user) }

  describe "GET #index" do
    it "renders the serie list" do
      get series_url

      assert_response :success
    end

    it "links the cover of the first book with a cover instead of embedding it" do
      book = books(:merged_book_two)
      book.update_columns(cover_bytes: "img", cover_type: "image/png")

      get series_url

      _(response.body).must_include cover_book_path(book, v: book.cache_version)
      _(response.body).wont_include "data:image/png;base64"
    end

    describe "pagination" do
      # 45 of these plus the 4 fixtures owned by :one fills two pages
      before { 45.times { |i| user.series.create!(name: "Zzz Page Serie #{i.to_s.rjust(2, "0")}") } }

      it "renders a single page and a lazy frame that pulls in the next one" do
        get series_url

        _(css_select("turbo-frame#series h3").size).must_equal 40
        frame = css_select("turbo-frame#series_page_2").first
        _(frame["loading"]).must_equal "lazy"
        _(frame["src"]).must_equal "/series?page=2"
        # Turbo only loads the frame once it is seen scrolling in, which needs it
        # to take up space: an empty one would never load.
        _(frame.text.strip).wont_be_empty
      end

      it "returns a later page inside its own frame, without the search form" do
        get series_url(page: 2)

        _(css_select("turbo-frame#series_page_2").size).must_equal 1
        _(css_select("turbo-frame#series_page_2 h3").size).must_equal 9
        _(css_select("turbo-frame#series").size).must_equal 0
        _(css_select("input[name=q]").size).must_equal 0
      end

      it "stops chaining frames once the last page is served" do
        get series_url(page: 2)

        _(css_select("turbo-frame#series_page_3").size).must_equal 0
      end

      it "carries the search into the next page url" do
        get series_url(q: "Page Serie")

        _(css_select("turbo-frame#series_page_2").first["src"]).must_include "q=Page+Serie"
      end

      it "lays a later page out like the one it continues" do
        get series_url
        cards = css_select("turbo-frame#series_page_2").first["class"]
        _(cards).must_match(/\bgrid\b/)
        _(cards).must_include "col-span-full" # so its rows join the grid above

        get series_url(view: "list")
        rows = css_select("turbo-frame#series_page_2").first["class"]
        _(rows).must_include "divide-y"
        _(rows).wont_match(/\bgrid\b/)
      end

      it "shows each serie on exactly one page" do
        get series_url
        first_page = css_select("turbo-frame#series h3").map { |h| h.text.strip }
        get series_url(page: 2)
        second_page = css_select("turbo-frame#series_page_2 h3").map { |h| h.text.strip }

        _(first_page & second_page).must_be_empty
        _((first_page + second_page).size).must_equal 49
      end

      it "leaves the json used by the autocomplete unpaginated" do
        get series_url(format: :json)

        _(JSON.parse(response.body).size).must_equal 49
      end
    end

    it "returns the filtered series as json" do
      get series_url(format: :json, q: "Shippuden")

      names = JSON.parse(response.body).map { |s| s["name"] }
      _(names).must_equal [ "Naruto Shippuden" ]
    end

    it "renders the card grid by default and the list rows when view=list" do
      get series_url
      _(response.body).must_include "grid grid-cols-2"

      get series_url(view: "list")
      _(response.body).must_include "divide-y"
    end

    it "remembers the chosen view in a cookie" do
      get series_url(view: "list")
      _(cookies[:view_mode]).must_equal "list"

      get series_url # no param: falls back to the cookie
      _(response.body).must_include "divide-y"
    end

    it "ignores an invalid view value" do
      get series_url(view: "bogus")

      _(response.body).must_include "grid grid-cols-2"
    end

    it "filters to unfinished series with filter=to_read" do
      finished = user.series.create!(name: "Zzz Finished Only", reading_state: "finished")

      get series_url(filter: "to_read")

      _(response.body).wont_include finished.name
      _(response.body).must_include series(:naruto).name # unset reading_state
    end

    it "filters to finished-but-unrated series with filter=to_reread" do
      to_reread = user.series.create!(name: "Zzz Reread Me", reading_state: "finished")

      get series_url(filter: "to_reread")

      _(response.body).must_include to_reread.name
      _(response.body).wont_include series(:naruto).name # not finished
    end
  end

  describe "GET #show" do
    it "renders the serie" do
      get serie_url(series(:to_merge))

      assert_response :success
    end
  end

  describe "GET #edit" do
    it "is blocked for non-admin users" do
      get edit_serie_url(serie)

      assert_redirected_to root_path
      assert_equal "Access denied.", flash[:alert]
    end

    it "renders for an admin" do
      sign_in_as(users(:admin))

      get edit_serie_url(series(:admin_serie))

      assert_response :success
    end
  end

  describe "PATCH #update" do
    it "updates the serie and redirects for an admin" do
      sign_in_as(users(:admin))

      patch serie_url(series(:admin_serie)), params: { serie: { name: "Renamed" } }

      assert_redirected_to serie_path(series(:admin_serie))
      assert_equal "Series was successfully updated.", flash[:notice]
      _(series(:admin_serie).reload.name).must_equal "Renamed"
    end

    it "re-renders edit for an admin when the update is invalid" do
      sign_in_as(users(:admin))

      patch serie_url(series(:admin_serie)), params: { serie: { name: "" } }

      assert_response :unprocessable_entity
      _(series(:admin_serie).reload.name).must_equal "Admin Owned Serie"
    end

    it "is blocked for non-admin users" do
      patch serie_url(serie), params: { serie: { name: "Renamed" } }

      assert_redirected_to root_path
      assert_equal "Access denied.", flash[:alert]
      _(serie.reload.name).wont_equal "Renamed"
    end
  end

  describe "GET #merge" do
    it "renders the merge page" do
      get merge_serie_url(serie)

      assert_response :success
    end
  end

  describe "GET #download" do
    it "sends a zip of the serie's books" do
      get download_serie_url(series(:to_merge))

      assert_response :success
      assert_equal "application/zip", response.media_type
    end

    it "redirects with an alert when the serie has no books" do
      get download_serie_url(serie)

      assert_redirected_to serie_path(serie)
      assert_equal "No books found", flash[:alert]
    end
  end

  describe "GET #download_all" do
    it "streams a zip of every book grouped into per-serie folders" do
      get download_all_series_url

      assert_response :success
      assert_equal "application/zip", response.media_type

      names = []
      Zip::File.open_buffer(StringIO.new(response.body)) { |zip| names = zip.map(&:name) }
      _(names).must_include "To Merge Serie/merged_one.epub"
      _(names.any? { |n| n.start_with?("No Series/") }).must_equal true
    end

    it "redirects with an alert when the user has no books" do
      sign_in_as(users(:admin))

      get download_all_series_url

      assert_redirected_to series_path
      assert_equal "You don't have any books to download yet.", flash[:alert]
    end
  end

  describe "POST #perform_merge" do
    it "hands the selected series to the merge service and redirects on success" do
      to_merge = series(:to_merge)
      service = Minitest::Mock.new
      service.expect(:call, { success: true, message: "Merged!" }) do |selected|
        selected.pluck(:id) == [ to_merge.id ]
      end

      SerieServices::MergeService.stub(:new, ->(*) { service }) do
        post perform_merge_serie_url(serie), params: { serie_ids: [ to_merge.id ] }
      end

      assert_mock service
      assert_redirected_to series_path
      assert_equal "Merged!", flash[:notice]
    end

    it "redirects back to the merge page with the service error on failure" do
      service = Minitest::Mock.new
      service.expect(:call, { success: false, error: "Boom" }) { true }

      SerieServices::MergeService.stub(:new, ->(*) { service }) do
        post perform_merge_serie_url(serie), params: { serie_ids: [ series(:to_merge).id ] }
      end

      assert_mock service
      assert_redirected_to merge_serie_path(serie)
      assert_equal "Boom", flash[:alert]
    end

    it "skips the service and redirects back when no series are selected" do
      SerieServices::MergeService.stub(:new, ->(*) { flunk "service should not be called" }) do
        post perform_merge_serie_url(serie), params: { serie_ids: [] }
      end

      assert_redirected_to merge_serie_path(serie)
      assert_equal "No series selected for merging.", flash[:alert]
    end
  end
end
