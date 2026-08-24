class Book < ApplicationRecord
  belongs_to :serie, optional: true
  belongs_to :user

  has_and_belongs_to_many :authors

  validates :filename, presence: true, uniqueness: { scope: :user_id }
  validates :epub_content, presence: true
  validates :serie_index, uniqueness: { scope: [ :user_id, :serie_id ] },
                          allow_nil: true, if: -> { serie_id.present? }

  HAS_COVER_SQL = "length(coalesce(books.cover_bytes, '')) > 0"

  scope :ordered, -> { order(:title, :id) }
  # Selects every column except the two binary ones, so listing pages don't drag
  # a whole epub per row into memory. Covers come from BooksController#cover, so
  # the bytes aren't needed either -- only whether there are any, hence has_cover.
  # Reading epub_content or cover_bytes off one of these raises.
  scope :without_blobs, -> {
    select(*(column_names - %w[epub_content cover_bytes]).map { |c| "books.#{c}" }, "#{HAS_COVER_SQL} AS has_cover")
  }
  scope :with_cover, -> { where(HAS_COVER_SQL) }
  scope :without_serie, -> { where(serie_id: nil) }
  scope :without_authors, -> { where.missing(:authors) }
  scope :incomplete, -> { left_joins(:authors).where("books.serie_id IS NULL OR authors.id IS NULL").distinct }

  enum :processing_status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }

  def cover?
    return has_cover.to_i.positive? if has_attribute?(:has_cover)

    cover_bytes.present?
  end

  def cover_mime_type
    cover_type.presence || "image/jpeg"
  end

  def author_names
    authors.pluck(:name).join(", ")
  end

  def epub
    BsEpub::Epub.new(epub_content, logger: Rails.logger, log_level: Rails.logger.level)
  end
end
