module AuthorServices
  class SimilarityService
    def initialize(author)
      @author = author
    end

    def call(limit = 10)
      return Author.none if @author.name.blank?

      query = @author.name.split(/[\s,]+/).reject(&:blank?)
                     .map { |token| %("#{token.gsub('"', '""')}") }.join(" OR ")

      Author.joins("JOIN authors_fts ON authors.id = authors_fts.rowid")
            .where("authors_fts MATCH ? AND authors.user_id = ? AND authors.id != ?",
                   query, @author.user_id, @author.id)
            .limit(limit)
    end
  end
end
