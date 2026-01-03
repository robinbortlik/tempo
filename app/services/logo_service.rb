class LogoService
  def initialize(settings)
    @settings = settings
  end

  def to_data_url
    return nil unless @settings.logo?

    blob = @settings.logo.blob
    content_type = blob.content_type
    base64_data = Base64.strict_encode64(blob.download)
    "data:#{content_type};base64,#{base64_data}"
  end

  def self.to_data_url(settings)
    new(settings).to_data_url
  end
end
