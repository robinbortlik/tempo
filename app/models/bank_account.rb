class BankAccount < ApplicationRecord
  # Associations
  has_many :clients, dependent: :nullify
  has_many :invoices, dependent: :nullify

  # Callbacks
  before_save :swap_default, if: :is_default_changed?
  after_save :ensure_default_exists

  # Validations
  validates :name, presence: true
  validates :iban, presence: true
  validate :iban_format, if: -> { iban.present? }

  # Scopes
  scope :default_accounts, -> { where(is_default: true) }

  # Class methods
  def self.default
    find_by(is_default: true)
  end

  private

  def iban_format
    return if Ibandit::IBAN.new(iban).valid?

    errors.add(:iban, "is not a valid IBAN")
  end

  def swap_default
    return unless is_default

    BankAccount.where.not(id: id).update_all(is_default: false)
  end

  def ensure_default_exists
    return if BankAccount.exists?(is_default: true)

    update_column(:is_default, true)
  end
end
