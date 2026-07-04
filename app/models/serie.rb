class Serie < ApplicationRecord
  belongs_to :user
  has_many :books, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :user_id, allow_blank: true }
  validates :rating, inclusion: { in: 1..5, allow_nil: true }

  # Scope to get series for a specific user
  scope :for_user, ->(user) { where(user: user) }
  scope :ordered, -> { order(:name) }
  scope :without_books, -> { where.missing(:books) }
  scope :to_read, -> { where(reading_state: [ nil, "unread", "reading" ]) }
  scope :to_reread, -> { where(reading_state: "finished", rating: nil) }

  after_create_commit :create_in_search_index
  after_update_commit :update_in_search_index
  after_destroy_commit :remove_from_search_index

  enum :completion_state, {
    ongoing: "ongoing",
    completed: "completed",
    cancelled: "cancelled"
  }

  enum :reading_state, {
    unread: "unread",
    reading: "reading",
    finished: "finished"
  }

  def similar_series(limit = 10)
    SerieServices::SimilarityService.new(self).call(limit)
  end

  def merge_with!(other_series)
    result = SerieServices::MergeService.new(self).call(other_series)
    result[:success]
  end

  def self.rebuild_search_index
    find_each do |serie|
      serie.send(:create_in_search_index)
    end

    connection.execute "INSERT INTO series_fts(series_fts) VALUES('rebuild')"
  end

  private

  def create_in_search_index
    execute_sql_with_binds "INSERT INTO series_fts (rowid, name, user_id) VALUES (?, ?, ?)", id, name, user_id
  rescue ActiveRecord::StatementInvalid
  end

  def update_in_search_index
    return unless saved_change_to_name?

    transaction do
      remove_from_search_index
      create_in_search_index
    end
  rescue ActiveRecord::StatementInvalid
  end

  def remove_from_search_index
    execute_sql_with_binds "INSERT INTO series_fts (series_fts, rowid, name, user_id) VALUES ('delete', ?, ?, ?)",
                          id, name, user_id
  rescue ActiveRecord::StatementInvalid
  end

  def execute_sql_with_binds(sql, *binds)
    self.class.connection.execute(
      self.class.sanitize_sql([ sql, *binds ])
    )
  end
end
