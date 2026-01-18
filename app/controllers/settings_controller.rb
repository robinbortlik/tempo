class SettingsController < ApplicationController
  def show
    render inertia: "Settings/Show", props: {
      settings: SettingsSerializer.new(settings, params: { url_helpers: self }).serializable_hash,
      bankAccounts: BankAccountSerializer.new(BankAccount.all.order(:name)).serializable_hash
    }
  end

  def update
    if settings.update(settings_params)
      redirect_to settings_path, notice: t("flash.settings.saved")
    else
      redirect_to settings_path, alert: settings.errors.full_messages.to_sentence
    end
  end

  def update_locale
    if Current.session.user.update(locale: params[:locale])
      redirect_to settings_path, notice: t("flash.settings.language_updated")
    else
      redirect_to settings_path, alert: Current.session.user.errors.full_messages.to_sentence
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
      :invoice_message,
      :logo,
      :main_currency
    )
  end
end
