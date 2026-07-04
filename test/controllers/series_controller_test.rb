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

    it "returns the filtered series as json" do
      get series_url(format: :json, q: "Shippuden")

      names = JSON.parse(response.body).map { |s| s["name"] }
      _(names).must_equal [ "Naruto Shippuden" ]
    end

    it "renders the card grid by default and the list rows when view=list" do
      get series_url
      _(response.body).must_include "grid grid-cols-5"

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

      _(response.body).must_include "grid grid-cols-5"
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
