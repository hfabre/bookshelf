module AuthorServices
  class MergeService
    def initialize(target_author)
      @target_author = target_author
    end

    def call(authors_to_merge)
      return { success: false, error: I18n.t("authors.merge_service.no_authors") } if authors_to_merge.empty?

      authors_to_merge = Array(authors_to_merge)

      # Validate all authors belong to the same user
      unless valid_authors_for_merge?(authors_to_merge)
        return { success: false, error: I18n.t("authors.merge_service.invalid") }
      end

      begin
        Author.transaction do
          merge_authors(authors_to_merge)
        end

        {
          success: true,
          message: I18n.t("authors.merge_service.success", count: authors_to_merge.count, name: @target_author.name),
          merged_count: authors_to_merge.count
        }
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotDestroyed => e
        {
          success: false,
          error: I18n.t("authors.merge_service.failure", error: e.message)
        }
      end
    end

    private

    def valid_authors_for_merge?(authors_to_merge)
      # Ensure all authors belong to the same user as target
      authors_to_merge.all? { |author| author.user_id == @target_author.user_id }
    end

    def merge_authors(authors_to_merge)
      authors_to_merge.each do |author|
        merge_single_author(author)
      end
    end

    def merge_single_author(author)
      # Transfer all books from the author to the target author
      author.books.find_each do |book|
        # Only add if not already associated to avoid duplicates
        unless @target_author.books.include?(book)
          @target_author.books << book
        end
      end

      # Remove the author after transferring all books
      author.destroy!
    end
  end
end
