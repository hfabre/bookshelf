module ApplicationHelper
  # Local path (path + query) of the page the current request came from, if any.
  def referer_path
    return nil if request.referer.blank?

    URI(request.referer).request_uri
  rescue URI::InvalidURIError
    nil
  end

  # TODO: add placeholder image when the book has no cover
  def book_cover(book, options = {})
    return unless book.cover?

    # v= lets the browser cache the cover for a year and still pick up an edit:
    # cache_version moves whenever the record is saved.
    image_tag cover_book_path(book, v: book.cache_version),
              { loading: "lazy", decoding: "async" }.merge(options)
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
    browsing_other_library? ? library_series_path(current_library_owner) : series_path
  end

  def current_authors_path
    browsing_other_library? ? library_authors_path(current_library_owner) : authors_path
  end

  # URL for the current page with the view mode swapped, preserving search/filter params.
  def view_toggle_url(mode)
    "#{request.path}?#{request.query_parameters.merge(view: mode).to_query}"
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
    browsing_other_library? ? library_serie_path(current_library_owner, serie) : serie_path(serie)
  end

  def author_show_path(author)
    browsing_other_library? ? library_author_path(current_library_owner, author) : author_path(author)
  end
end
