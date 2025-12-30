class SettingsController < ApplicationController
  def show
    render inertia: "Settings/Show", props: {
      settings: settings_json
    }
  end

  def update
    if settings.update(settings_params)
      redirect_to settings_path, notice: "Settings saved successfully."
    else
      redirect_to settings_path, alert: settings.errors.full_messages.first
    end
  end

  private

  def settings
    @settings ||= Setting.instance
  end

  def settings_params
    params.require(:setting).permit(
      :company_name,
      :address,
      :email,
      :phone,
      :vat_id,
      :company_registration,
      :bank_name,
      :bank_account,
      :bank_swift,
      :logo
    )
  end

  def settings_json
    {
      id: settings.id,
      company_name: settings.company_name,
      address: settings.address,
      email: settings.email,
      phone: settings.phone,
      vat_id: settings.vat_id,
      company_registration: settings.company_registration,
      bank_name: settings.bank_name,
      bank_account: settings.bank_account,
      bank_swift: settings.bank_swift,
      logo_url: settings.logo? ? url_for(settings.logo) : nil
    }
  end
end
