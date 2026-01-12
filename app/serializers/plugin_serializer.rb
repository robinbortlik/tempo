class PluginSerializer
  include Alba::Resource

  # Full detail for single plugin
  attributes :plugin_name, :plugin_version, :plugin_description,
             :enabled, :configured, :has_settings

  attribute :created_at do |plugin_summary|
    plugin_summary[:created_at]&.iso8601
  end

  attribute :updated_at do |plugin_summary|
    plugin_summary[:updated_at]&.iso8601
  end

  # For list view - includes sync stats
  class List
    include Alba::Resource

    attributes :plugin_name, :plugin_version, :plugin_description,
               :enabled, :configured

    attribute :last_sync_at do |plugin_summary|
      params[:sync_stats]&.dig(plugin_summary[:plugin_name], :last_sync, :completed_at)
    end

    attribute :last_sync_status do |plugin_summary|
      params[:sync_stats]&.dig(plugin_summary[:plugin_name], :last_sync, :status)
    end

    attribute :total_syncs do |plugin_summary|
      params[:sync_stats]&.dig(plugin_summary[:plugin_name], :total_syncs) || 0
    end

    attribute :success_rate do |plugin_summary|
      params[:sync_stats]&.dig(plugin_summary[:plugin_name], :success_rate) || 0.0
    end
  end
end
