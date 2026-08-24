class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :books, dependent: :destroy
  has_many :series, class_name: "Serie", dependent: :destroy
  has_many :authors, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Libraries the given user may read: their own, plus every public one.
  scope :with_readable_library, ->(viewer) { where(public_library: true).or(where(id: viewer.id)) }

  # Public-facing label for shared libraries; avoids exposing the full email.
  def display_name
    email_address.split("@").first
  end
end
