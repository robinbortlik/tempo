class PluginsController < ApplicationController
  before_action :set_plugin_name, only: [:enable, :disable, :sync]

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
end
