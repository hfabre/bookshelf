module Paginated
  extend ActiveSupport::Concern

  PER_PAGE = 40

  private

  # Pages the browse lists for the infinite scroll. Loads one row more than the
  # page needs, which tells us whether a next page exists without a COUNT.
  def paginate(scope)
    @page = [ params[:page].to_i, 1 ].max
    records = scope.limit(PER_PAGE + 1).offset((@page - 1) * PER_PAGE).to_a
    @has_more = records.size > PER_PAGE

    records.first(PER_PAGE)
  end
end
