module AuthenticationHelpers
  def sign_in(user = nil)
    user ||= create(:user, password: "password123")
    post session_path, params: { email_address: user.email_address, password: "password123" }
    user
  end

  def sign_out
    delete session_path
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
  config.include AuthenticationHelpers, type: :system
end
