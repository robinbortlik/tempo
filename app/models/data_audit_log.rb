# Stores audit trail entries for data changes made by plugins
#
# Each entry records:
# - What record was changed (auditable_type + auditable_id)
# - What action occurred (create, update, destroy)
# - What changed (changes_made as JSON)
# - Who/what made the change (source, sync_history_id)
#
class DataAuditLog < ApplicationRecord
  # Associations
  belongs_to :auditable, polymorphic: true, optional: true
  belongs_to :sync_history, optional: true

  # Enums
  enum :action, { create_action: "create", update_action: "update", destroy_action: "destroy" }

  # Validations
  validates :auditable_type, presence: true
  validates :auditable_id, presence: true
  validates :action, presence: true

  # Scopes - By type
  scope :for_type, ->(type) { where(auditable_type: type) }
  scope :for_record, ->(record) { where(auditable_type: record.class.name, auditable_id: record.id) }
  scope :for_record_id, ->(type, id) { where(auditable_type: type, auditable_id: id) }

  # Scopes - By source
  scope :for_source, ->(source) { where(source: source) }
  scope :from_plugins, -> { where.not(source: "user").where.not(source: nil) }
  scope :from_user, -> { where(source: "user") }

  # Scopes - By action
  scope :creates, -> { create_action }
  scope :updates, -> { update_action }
  scope :destroys, -> { destroy_action }

  # Scopes - Time-based
  scope :recent, -> { order(created_at: :desc).limit(50) }
  scope :today, -> { where(created_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :for_sync, ->(sync_history_id) { where(sync_history_id: sync_history_id) }

  # Returns human-readable description of the change
  # @return [String] description like "Created MoneyTransaction #123"
  def description
    case action
    when "create"
      "Created #{auditable_type} ##{auditable_id}"
    when "update"
      changed_attrs = changes_made&.keys&.join(", ") || "attributes"
      "Updated #{auditable_type} ##{auditable_id} (#{changed_attrs})"
    when "destroy"
      "Destroyed #{auditable_type} ##{auditable_id}"
    end
  end

  # Returns summary hash for UI display
  # @return [Hash]
  def summary
    {
      id: id,
      auditable_type: auditable_type,
      auditable_id: auditable_id,
      action: action,
      source: source,
      sync_history_id: sync_history_id,
      changes_made: changes_made,
      description: description,
      created_at: created_at
    }
  end

  class << self
    # Returns statistics for a specific source (plugin)
    # @param source [String] the plugin name
    # @return [Hash] statistics
    def stats_for_source(source)
      scope = for_source(source)

      {
        source: source,
        total_changes: scope.count,
        creates: scope.creates.count,
        updates: scope.updates.count,
        destroys: scope.destroys.count,
        affected_records: scope.distinct.count(:auditable_id),
        affected_types: scope.distinct.pluck(:auditable_type),
        changes_today: scope.today.count,
        last_change: scope.order(created_at: :desc).first&.summary
      }
    end

    # Returns audit history for a specific record
    # @param record [ActiveRecord::Base] the record to get history for
    # @return [Array<Hash>] array of audit entry summaries
    def history_for(record)
      for_record(record).order(created_at: :desc).map(&:summary)
    end

    # Returns recent changes grouped by sync operation
    # @param limit [Integer] number of sync operations to include
    # @return [Hash] sync_history_id => [audit entries]
    def recent_by_sync(limit: 10)
      result = {}

      # Get distinct sync IDs from recent changes
      sync_ids = where.not(sync_history_id: nil)
                   .order(created_at: :desc)
                   .limit(limit * 10)
                   .distinct
                   .pluck(:sync_history_id)
                   .first(limit)

      sync_ids.each do |sync_id|
        result[sync_id] = for_sync(sync_id).order(created_at: :asc).map(&:summary)
      end

      result
    end
  end
end
