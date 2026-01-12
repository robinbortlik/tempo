# Application-wide current attributes using Rails CurrentAttributes
#
# Provides thread-safe storage for:
# - session: The current user's session
# - audit_source: The source of data changes (plugin name or "user")
# - audit_sync_history_id: The SyncHistory ID for correlating changes
#
class Current < ActiveSupport::CurrentAttributes
  attribute :session

  # Audit trail context
  attribute :audit_source
  attribute :audit_sync_history_id

  delegate :user, to: :session, allow_nil: true

  # Set audit context for plugin operations
  # @param source [String] plugin name or identifier
  # @param sync_history_id [Integer, nil] optional sync history ID
  def self.with_audit_context(source:, sync_history_id: nil)
    previous_source = audit_source
    previous_sync_history_id = audit_sync_history_id

    self.audit_source = source
    self.audit_sync_history_id = sync_history_id

    yield
  ensure
    self.audit_source = previous_source
    self.audit_sync_history_id = previous_sync_history_id
  end
end
