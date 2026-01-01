InertiaRails.configure do |config|
  config.version = ViteRuby.digest
  config.default_render = true
  config.always_include_errors_hash = true
  config.layout = "inertia"
end
