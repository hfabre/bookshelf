class Author < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :books

  validates :name, presence: true, uniqueness: { scope: :user_id }

  scope :for_user, ->(user) { where(user: user) }
  scope :ordered, -> { order(:name) }

  # Keep FTS5 search index in sync
  after_create_commit :create_in_search_index
  after_update_commit :update_in_search_index
  after_destroy_commit :remove_from_search_index

  # Find similar authors using the dedicated service
  def similar_authors(limit = 10)
    AuthorServices::SimilarityService.new(self).call(limit)
  end

  # Merge this author with other authors using the dedicated service
  def merge_with!(other_authors)
    result = AuthorServices::MergeService.new(self).call(other_authors)
    result[:success]
  end

  # Rebuild the FTS5 search index (useful for existing data or tests)
  def self.rebuild_search_index
    # First, populate any missing authors
    find_each do |author|
      author.send(:create_in_search_index)
    end

    # Then rebuild the index for optimal performance
    connection.execute "INSERT INTO authors_fts(authors_fts) VALUES('rebuild')"
  end

  private

  def create_in_search_index
    execute_sql_with_binds "INSERT INTO authors_fts (rowid, name, user_id) VALUES (?, ?, ?)", id, name, user_id
  rescue ActiveRecord::StatementInvalid
    # FTS table might not exist yet, ignore
  end

  def update_in_search_index
    return unless saved_change_to_name?

    transaction do
      remove_from_search_index
      create_in_search_index
    end
  rescue ActiveRecord::StatementInvalid
    # FTS table might not exist yet, ignore
  end

  def remove_from_search_index
    execute_sql_with_binds "INSERT INTO authors_fts (authors_fts, rowid, name, user_id) VALUES ('delete', ?, ?, ?)",
                          id_previously_was || id,
                          name_previously_was || name,
                          user_id_previously_was || user_id
  rescue ActiveRecord::StatementInvalid
    # FTS table might not exist yet, ignore
  end

  def execute_sql_with_binds(*statement)
    self.class.connection.execute self.class.sanitize_sql(statement)
  end
end
