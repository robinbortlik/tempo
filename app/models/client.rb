class Client < ApplicationRecord
  # Associations
  has_many :projects, dependent: :destroy
  # has_many :invoices, dependent: :destroy

  # Callbacks
  before_validation :generate_share_token, on: :create

  # Validations
  validates :name, presence: true
  validates :hourly_rate, numericality: { greater_than: 0 }, allow_nil: true
  validates :currency, format: { with: /\A[A-Z]{3}\z/, message: "must be 3 uppercase letters (e.g., EUR, USD, GBP)" },
                       allow_blank: true
  validates :share_token, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" },
                    allow_blank: true

  private

  def generate_share_token
    self.share_token ||= SecureRandom.uuid
  end
end
