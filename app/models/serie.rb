class Serie < ApplicationRecord
  has_many :books, dependent: :destroy

  validates :name, presence: true, uniqueness: { allow_blank: true }
  validates :rating, inclusion: { in: 1..5, allow_nil: true }

  # Get user through books (all books in a series belong to same user)
  def user
    books.first&.user
  end

  # Scope to get series for a specific user
  scope :for_user, ->(user) { joins(:books).where(books: { user: user }).distinct }
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
