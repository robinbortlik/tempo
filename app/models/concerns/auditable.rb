# Concern for models that should have their changes tracked in the audit log
#
# Usage:
#   class MoneyTransaction < ApplicationRecord
#     include Auditable
#   end
#
# All create, update, and destroy operations will be logged to DataAuditLog
# with source attribution from Current.audit_source
#
module Auditable
  extend ActiveSupport::Concern

  included do
    after_create :log_create
    after_update :log_update
    after_destroy :log_destroy
  end

  # Returns the audit history for this record
  # @return [Array<Hash>] array of audit entry summaries
  def audit_history
    DataAuditLog.history_for(self)
  end

  # Returns the most recent audit entry for this record
  # @return [DataAuditLog, nil]
  def last_audit_entry
    DataAuditLog.for_record(self).order(created_at: :desc).first
  end

  # Returns true if this record was created by a plugin
  # @return [Boolean]
  def created_by_plugin?
    first_audit = DataAuditLog.for_record(self).creates.order(created_at: :asc).first
    first_audit.present? && first_audit.source.present? && first_audit.source != "user"
  end

  # Returns the source that created this record
  # @return [String, nil]
  def created_by
    DataAuditLog.for_record(self).creates.order(created_at: :asc).first&.source
  end

  private

  def log_create
    log_audit_entry("create", nil)
  end

  def log_update
    return if saved_changes.blank?

    # Filter out timestamps and id from changes
    relevant_changes = saved_changes.except("id", "created_at", "updated_at")
    return if relevant_changes.blank?

    # Transform saved_changes format ([old, new]) to a cleaner format
    changes_hash = relevant_changes.transform_values do |change|
      { from: change[0], to: change[1] }
    end

    log_audit_entry("update", changes_hash)
  end

  def log_destroy
    # Store key attributes for reference after destruction
    final_state = attributes.except("id", "created_at", "updated_at")
    log_audit_entry("destroy", { final_state: final_state })
  end

  def log_audit_entry(action, changes)
    DataAuditLog.create!(
      auditable_type: self.class.name,
      auditable_id: id,
      action: action,
      changes_made: changes,
      source: Current.audit_source,
      sync_history_id: Current.audit_sync_history_id
    )
  rescue StandardError => e
    # Don't let audit logging failures break the main operation
    Rails.logger.error("Failed to create audit log: #{e.message}")
  end
end
