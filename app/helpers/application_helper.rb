module ApplicationHelper
  def book_cover(book, options = {})
    if book.cover_data_url.present?
      image_tag book.cover_data_url, options
    else
      # TODO: add placeholder image
      # image_tag "cover-placeholder.png", options
    end
  end

  def current_library_owner
    @library_owner || current_user
  end

  def browsing_other_library?
    current_library_owner != current_user
  end

  # Navigation path helpers
  def current_books_path
    browsing_other_library? ? library_books_path(current_library_owner) : books_path
  end

  def current_series_path
    browsing_other_library? ? library_series_path(current_library_owner) : series_index_path
  end

  def current_authors_path
    browsing_other_library? ? library_authors_path(current_library_owner) : authors_path
  end

  # Search path helpers
  def books_search_path
    current_books_path
  end

  def series_search_path
    current_series_path
  end

  def authors_search_path
    current_authors_path
  end

  # Back link helpers
  def series_back_path
    current_series_path
  end

  def authors_back_path
    current_authors_path
  end

  # Show page link helpers
  def serie_show_path(serie)
    browsing_other_library? ? library_serie_path(current_library_owner, serie) : series_path(serie)
  end

  def author_show_path(author)
    browsing_other_library? ? library_author_path(current_library_owner, author) : author_path(author)
  end
end
