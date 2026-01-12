class PluginsController < ApplicationController
  before_action :set_plugin_name, only: [:enable, :disable, :sync, :configure, :update_credentials, :update_settings, :clear_credentials, :history, :show_sync]

  def index
    plugins = PluginConfigurationService.all_plugins_summary
    sync_stats = build_sync_stats(plugins)

    render inertia: "Plugins/Index", props: {
      plugins: PluginSerializer::List.new(plugins, params: { sync_stats: sync_stats }).serializable_hash
    }
  end

  def enable
    service = PluginConfigurationService.new(plugin_name: @plugin_name)
    result = service.enable!

    if result[:success]
      redirect_to plugins_path, notice: t("flash.plugins.enabled", name: @plugin_name)
    else
      redirect_to plugins_path, alert: result[:errors].to_sentence
    end
  rescue PluginRegistry::NotFoundError => e
    redirect_to plugins_path, alert: e.message
  end

  def disable
    service = PluginConfigurationService.new(plugin_name: @plugin_name)
    result = service.disable!

    if result[:success]
      redirect_to plugins_path, notice: t("flash.plugins.disabled", name: @plugin_name)
    else
      redirect_to plugins_path, alert: result[:errors].to_sentence
    end
  rescue PluginRegistry::NotFoundError => e
    redirect_to plugins_path, alert: e.message
  end

  def sync
    service = SyncExecutionService.new
    result = service.execute(plugin_name: @plugin_name)

    if result[:success]
      redirect_to plugins_path, notice: t("flash.plugins.sync_complete", name: @plugin_name)
    else
      redirect_to plugins_path, alert: t("flash.plugins.sync_failed", name: @plugin_name, error: result[:error])
    end
  rescue PluginRegistry::NotFoundError => e
    redirect_to plugins_path, alert: e.message
  end

  def configure
    service = PluginConfigurationService.new(plugin_name: @plugin_name)

    render inertia: "Plugins/Configure", props: {
      plugin: PluginSerializer.new(service.summary).serializable_hash,
      credentials: mask_credentials(service.configuration.credentials_hash),
      settings: service.configuration.settings_hash,
      credential_fields: credential_fields_for(@plugin_name),
      setting_fields: setting_fields_for(@plugin_name)
    }
  rescue PluginRegistry::NotFoundError => e
    redirect_to plugins_path, alert: e.message
  end

  def update_credentials
    service = PluginConfigurationService.new(plugin_name: @plugin_name)
    result = service.replace_credentials(credentials_params.to_h)

    if result[:success]
      redirect_to configure_plugin_path(@plugin_name), notice: t("flash.plugins.credentials_saved")
    else
      redirect_to configure_plugin_path(@plugin_name), alert: result[:errors].to_sentence
    end
  rescue PluginRegistry::NotFoundError => e
    redirect_to plugins_path, alert: e.message
  end

  def update_settings
    service = PluginConfigurationService.new(plugin_name: @plugin_name)
    result = service.replace_settings(settings_params.to_h)

    if result[:success]
      redirect_to configure_plugin_path(@plugin_name), notice: t("flash.plugins.settings_saved")
    else
      redirect_to configure_plugin_path(@plugin_name), alert: result[:errors].to_sentence
    end
  rescue PluginRegistry::NotFoundError => e
    redirect_to plugins_path, alert: e.message
  end

  def clear_credentials
    service = PluginConfigurationService.new(plugin_name: @plugin_name)
    result = service.clear_credentials!

    if result[:success]
      redirect_to configure_plugin_path(@plugin_name), notice: t("flash.plugins.credentials_cleared")
    else
      redirect_to configure_plugin_path(@plugin_name), alert: result[:errors].to_sentence
    end
  rescue PluginRegistry::NotFoundError => e
    redirect_to plugins_path, alert: e.message
  end

  def history
    service = PluginConfigurationService.new(plugin_name: @plugin_name)
    sync_histories = SyncHistory.for_plugin(@plugin_name)
                                .order(created_at: :desc)
                                .limit(50)

    render inertia: "Plugins/History", props: {
      plugin: PluginSerializer.new(service.summary).serializable_hash,
      sync_histories: SyncHistorySerializer::List.new(sync_histories).serializable_hash,
      stats: SyncHistory.stats_for_plugin(@plugin_name),
      aggregate_stats: SyncHistory.aggregate_stats
    }
  rescue PluginRegistry::NotFoundError => e
    redirect_to plugins_path, alert: e.message
  end

  def show_sync
    sync_history = SyncHistory.find(params[:sync_id])

    # Verify sync belongs to the plugin
    unless sync_history.plugin_name == @plugin_name
      redirect_to history_plugin_path(@plugin_name), alert: t("flash.plugins.sync_not_found")
      return
    end

    service = PluginConfigurationService.new(plugin_name: @plugin_name)

    render inertia: "Plugins/SyncDetail", props: {
      plugin: PluginSerializer.new(service.summary).serializable_hash,
      sync_history: SyncHistorySerializer::Detail.new(sync_history).serializable_hash
    }
  rescue ActiveRecord::RecordNotFound
    redirect_to history_plugin_path(@plugin_name), alert: t("flash.plugins.sync_not_found")
  rescue PluginRegistry::NotFoundError => e
    redirect_to plugins_path, alert: e.message
  end

  private

  def set_plugin_name
    @plugin_name = params[:id]
  end

  def build_sync_stats(plugins)
    stats = {}
    plugins.each do |plugin|
      stats[plugin[:plugin_name]] = SyncHistory.stats_for_plugin(plugin[:plugin_name])
    end
    stats
  end

  # Mask credential values for display (show only last 4 chars)
  def mask_credentials(credentials)
    credentials.transform_values do |value|
      next value if value.nil? || value.to_s.length <= 4
      "#{"*" * (value.to_s.length - 4)}#{value.to_s[-4..]}"
    end
  end

  # Define credential fields per plugin (extensible)
  # Override in subclass or use plugin metadata in future
  def credential_fields_for(plugin_name)
    # Default credential fields - plugins can define their own via class method
    plugin_class = PluginRegistry.find(plugin_name)

    if plugin_class.respond_to?(:credential_fields)
      plugin_class.credential_fields
    else
      # Default fields for most API integrations
      [
        { name: "api_key", label: "API Key", type: "password", required: true },
        { name: "api_secret", label: "API Secret", type: "password", required: false }
      ]
    end
  end

  # Define setting fields per plugin (extensible)
  def setting_fields_for(plugin_name)
    plugin_class = PluginRegistry.find(plugin_name)

    if plugin_class.respond_to?(:setting_fields)
      plugin_class.setting_fields
    else
      # Default settings
      [
        { name: "sync_from_date", label: "Sync from date", type: "date", required: false },
        { name: "import_limit", label: "Import limit", type: "number", required: false }
      ]
    end
  end

  def credentials_params
    # Permit all credential fields dynamically
    permitted_keys = credential_fields_for(@plugin_name).map { |f| f[:name].to_sym }
    params.require(:credentials).permit(permitted_keys)
  end

  def settings_params
    # Permit all setting fields dynamically
    permitted_keys = setting_fields_for(@plugin_name).map { |f| f[:name].to_sym }
    params.require(:settings).permit(permitted_keys)
  end
end
