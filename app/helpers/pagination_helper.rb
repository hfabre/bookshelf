module PaginationHelper
  CONTAINER_CLASSES = {
    "cards" => "grid grid-cols-5 gap-8",
    "list" => "flex flex-col divide-y divide-gray-100 rounded-lg border border-gray-100 bg-white shadow-sm"
  }.freeze

  # A page after the first sits inside the container above it, so it repeats the
  # layout but not the frame around it.
  PAGE_CLASSES = {
    "cards" => "col-span-full grid grid-cols-5 gap-8",
    "list" => "flex flex-col divide-y divide-gray-100"
  }.freeze

  def index_container_class
    CONTAINER_CLASSES.fetch(@view_mode)
  end

  def index_page_class
    PAGE_CLASSES.fetch(@view_mode)
  end

  # Infinite scroll with no javascript: an empty frame that Turbo loads once it
  # scrolls into view, and whose response ends with the frame for the page after
  # it. The placeholder gives the frame a box, so it can be seen scrolling in.
  def next_page_frame(name)
    return unless @has_more

    turbo_frame_tag "#{name}_page_#{@page + 1}",
                    src: page_url(@page + 1),
                    loading: "lazy",
                    class: index_page_class do
      tag.div t("common.loading"), class: "col-span-full py-6 text-center text-sm text-gray-500"
    end
  end

  def page_url(page)
    "#{request.path}?#{request.query_parameters.merge(page: page).to_query}"
  end
end
