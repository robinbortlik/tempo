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
    wait_until: "networkidle0"
  }
end
