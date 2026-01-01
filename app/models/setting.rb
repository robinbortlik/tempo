class Setting < ApplicationRecord
  # Active Storage attachment for company logo
  has_one_attached :logo

  # Validations
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" },
                    allow_blank: true
  validate :iban_format, if: -> { iban.present? }
  validates :invoice_message, length: { maximum: 500 }, allow_blank: true

  # Singleton pattern - ensures only one settings record exists
  def self.instance
    first_or_create!
  end

  # Convenience method to check if logo is attached
  def logo?
    logo.attached?
  end

  private

  def iban_format
    return if Ibandit::IBAN.new(iban).valid?

    errors.add(:iban, "is not a valid IBAN")
  end
end
