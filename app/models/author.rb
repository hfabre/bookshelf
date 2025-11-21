class Author < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :books

  validates :name, presence: true, uniqueness: { scope: :user_id }

  scope :for_user, ->(user) { where(user: user) }
  scope :ordered, -> { order(:name) }
end
