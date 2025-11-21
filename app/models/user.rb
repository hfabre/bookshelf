class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :books, dependent: :destroy
  has_many :series, class_name: "Serie", dependent: :destroy
  has_many :authors, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
