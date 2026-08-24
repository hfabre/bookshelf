class Author < ApplicationRecord
  include Searchable

  belongs_to :user
  has_and_belongs_to_many :books

  validates :name, presence: true, uniqueness: { scope: :user_id }

  scope :for_user, ->(user) { where(user: user) }
  scope :ordered, -> { order(:name, :id) }
  scope :without_books, -> { where.missing(:books) }

  # Merge this author with other authors using the dedicated service
  def merge_with!(other_authors)
    result = AuthorServices::MergeService.new(self).call(other_authors)
    result[:success]
  end
end
