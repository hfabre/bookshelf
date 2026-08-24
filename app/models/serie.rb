class Serie < ApplicationRecord
  include Searchable

  belongs_to :user
  has_many :books, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :user_id, allow_blank: true }
  validates :rating, inclusion: { in: 1..5, allow_nil: true }

  # Scope to get series for a specific user
  scope :for_user, ->(user) { where(user: user) }
  scope :ordered, -> { order(:name, :id) }
  scope :without_books, -> { where.missing(:books) }
  scope :to_read, -> { where(reading_state: [ nil, "unread", "reading" ]) }
  scope :to_reread, -> { where(reading_state: "finished", rating: nil) }

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

  def merge_with!(other_series)
    result = SerieServices::MergeService.new(self).call(other_series)
    result[:success]
  end
end
