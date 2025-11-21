class Serie < ApplicationRecord
  belongs_to :user
  has_many :books, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :user_id, allow_blank: true }
  validates :rating, inclusion: { in: 1..5, allow_nil: true }

  # Scope to get series for a specific user
  scope :for_user, ->(user) { where(user: user) }
  scope :ordered, -> { order(:name) }

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
end
