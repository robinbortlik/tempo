class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale

  private

  def set_locale
    I18n.locale = Current.session&.user&.locale || I18n.default_locale
  end

  public

  # Share flash messages with all Inertia pages
  inertia_share flash: -> {
    {
      alert: flash[:alert],
      notice: flash[:notice]
    }
  }

  # Share current user auth info with all Inertia pages
  inertia_share auth: -> {
    if Current.session&.user
      {
        user: {
          email_address: Current.session.user.email_address
        }
      }
    else
      {}
    end
  }

  # Share user locale with all Inertia pages
  inertia_share locale: -> {
    Current.session&.user&.locale || "en"
  }
end
