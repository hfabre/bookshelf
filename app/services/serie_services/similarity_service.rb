module SerieServices
  class SimilarityService
    def initialize(serie)
      @serie = serie
    end

    def call(limit = 10)
      return Serie.none if @serie.name.blank?

      query = @serie.name.split(/[\s,]+/).reject(&:blank?).join(" OR ")

      Serie.joins("JOIN series_fts ON series.id = series_fts.rowid")
           .where("series_fts MATCH ? AND series.user_id = ? AND series.id != ?",
                  query, @serie.user_id, @serie.id)
           .limit(limit)
    end
  end
end
