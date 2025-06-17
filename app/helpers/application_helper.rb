module ApplicationHelper
  def book_cover(book, options = {})
    if book.cover_data_url.present?
      image_tag book.cover_data_url, options
    else
      # TODO: add placeholder image
      # image_tag "cover-placeholder.png", options
    end
  end
end
