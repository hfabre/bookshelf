class Serie < ApplicationRecord
  belongs_to :user
  has_many :books, foreign_key: :serie_id, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :rating, inclusion: { in: 1..5, allow_nil: true }

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

  scope :ordered, -> { order(:name) }
end
