class PluginConfiguration < ApplicationRecord
  # Encryption
  encrypts :credentials

  # Validations
  validates :plugin_name, presence: true, uniqueness: true

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
end
