require "base64"

class Book < ApplicationRecord
  belongs_to :serie, optional: true
  belongs_to :user

  has_and_belongs_to_many :authors

  validates :filename, presence: true, uniqueness: { scope: :user_id }
  validates :epub_content, presence: true
  validates :serie_index, uniqueness: { scope: [ :user_id, :serie_id ] },
                          allow_nil: true, if: -> { serie_id.present? }

  scope :ordered, -> { order(:title) }
  scope :without_serie, -> { where(serie_id: nil) }
  scope :without_authors, -> { where.missing(:authors) }
  scope :incomplete, -> { left_joins(:authors).where("books.serie_id IS NULL OR authors.id IS NULL").distinct }

  enum :processing_status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }

  def cover_data_url
    return nil unless cover?

    mime_type = cover_type || "image/jpeg"
    base64_data = Base64.encode64(cover_bytes)
    "data:#{mime_type};base64,#{base64_data}"
  end

  def cover?
    cover_bytes.present?
  end

  def author_names
    authors.pluck(:name).join(", ")
  end

  def epub
    BsEpub::Epub.new(epub_content, logger: Rails.logger, log_level: Rails.logger.level)
  end
end
