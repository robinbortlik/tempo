class PluginConfiguration < ApplicationRecord
  # Encryption
  encrypts :credentials

  # Validations
  validates :plugin_name, presence: true, uniqueness: true

  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }
  scope :configured, -> { where.not(credentials: [ nil, "" ]) }

  # Returns the credentials as a parsed hash
  def credentials_hash
    return {} if credentials.blank?

    JSON.parse(credentials)
  rescue JSON::ParserError
    {}
  end

  # Returns the settings as a parsed hash
  def settings_hash
    return {} if settings.blank?

    JSON.parse(settings)
  rescue JSON::ParserError
    {}
  end

  # Returns whether the plugin has any credentials stored
  def has_credentials?
    credentials.present?
  end

  # Returns whether the plugin has any settings stored
  def has_settings?
    settings.present?
  end
end
