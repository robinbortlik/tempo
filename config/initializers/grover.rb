# frozen_string_literal: true

Grover.configure do |config|
  config.options = {
    format: "A4",
    margin: {
      top: "20mm",
      bottom: "20mm",
      left: "20mm",
      right: "20mm"
    },
    print_background: true,
    prefer_css_page_size: false,
    display_url: false,
    # Puppeteer timeout and wait options
    timeout: 30_000, # 30 seconds
    wait_until: "networkidle0",
    # Use system Chromium executable if set (for Docker)
    executable_path: ENV.fetch("PUPPETEER_EXECUTABLE_PATH", nil)
  }

  # Launch arguments for Chromium (required for Docker environments)
  config.launch_args = if ENV["GROVER_NO_SANDBOX"] == "true"
    ["--no-sandbox", "--disable-setuid-sandbox", "--disable-dev-shm-usage"]
  else
    []
  end
end
