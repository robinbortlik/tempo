require "fugit"

# Orchestrates scheduled plugin syncs based on cron expressions.
#
# This job runs every minute via solid_queue recurring schedule and checks
# each enabled plugin's cron_schedule setting to determine if a sync should run.
#
# Usage:
#   # Via recurring schedule (automatic, every minute)
#   # Configured in config/recurring.yml
#
#   # Manual execution (testing)
#   PluginSyncOrchestratorJob.perform_now
#
class PluginSyncOrchestratorJob < ApplicationJob
  queue_as :default

  def perform
    enabled_plugins.each do |config|
      process_plugin(config)
    end
  end

  private

  def enabled_plugins
    PluginConfiguration.enabled
  end

  def process_plugin(config)
    return unless schedule_matches?(config)

    execute_sync(config)
  rescue StandardError => e
    Rails.logger.error("Failed to sync plugin '#{config.plugin_name}': #{e.message}")
  end

  def schedule_matches?(config)
    cron_expression = config.settings_hash["cron_schedule"]
    return false if cron_expression.blank?

    cron = Fugit::Cron.parse(cron_expression)
    return false unless cron

    cron.match?(Time.current)
  end

  def execute_sync(config)
    SyncExecutionService.new.execute(plugin_name: config.plugin_name)
  end
end
