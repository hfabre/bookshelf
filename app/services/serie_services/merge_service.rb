module SerieServices
  class MergeService
    def initialize(target_serie)
      @target_serie = target_serie
    end

    def call(series_to_merge)
      return { success: false, error: "No series provided for merging" } if series_to_merge.empty?

      series_to_merge = Array(series_to_merge)

      unless valid_series_for_merge?(series_to_merge)
        return { success: false, error: "Invalid series for merging" }
      end

      begin
        Serie.transaction do
          merge_series(series_to_merge)
        end

        {
          success: true,
          message: "Successfully merged #{series_to_merge.count} series into #{@target_serie.name}",
          merged_count: series_to_merge.count
        }
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotDestroyed => e
        {
          success: false,
          error: "Failed to merge series: #{e.message}"
        }
      end
    end

    private

    def valid_series_for_merge?(series_to_merge)
      series_to_merge.all? { |serie| serie.user_id == @target_serie.user_id }
    end

    def merge_series(series_to_merge)
      series_to_merge.each do |serie|
        merge_single_serie(serie)
      end
    end

    def merge_single_serie(serie)
      serie.books.find_each do |book|
        book.update!(serie: @target_serie)
      end

      serie.destroy!
    end
  end
end
