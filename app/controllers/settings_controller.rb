class SettingsController < ApplicationController
  def show
    render inertia: "Settings/Show", props: {
      settings: SettingsSerializer.new(settings, params: { url_helpers: self }).serializable_hash
    }
  end

  def update
    if settings.update(settings_params)
      redirect_to settings_path, notice: "Settings saved successfully."
    else
      redirect_to settings_path, alert: settings.errors.full_messages.to_sentence
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
      :iban,
      :invoice_message,
      :logo
    )
  end
end
