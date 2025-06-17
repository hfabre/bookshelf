class Author < ApplicationRecord
  has_and_belongs_to_many :books

  validates :name, presence: true, uniqueness: true

  scope :ordered, -> { order(:name) }
end
