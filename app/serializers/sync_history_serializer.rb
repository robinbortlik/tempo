class SyncHistorySerializer
  include Alba::Resource

  attributes :id, :plugin_name, :status,
             :records_processed, :records_created, :records_updated,
             :error_message

  attribute :started_at do |history|
    history.started_at&.iso8601
  end

  attribute :completed_at do |history|
    history.completed_at&.iso8601
  end

  attribute :duration do |history|
    history.duration
  end

  attribute :duration_formatted do |history|
    history.duration_formatted
  end

  attribute :successful do |history|
    history.successful?
  end

  # List variant - for history list view
  class List
    include Alba::Resource

    attributes :id, :status,
               :records_processed, :records_created, :records_updated,
               :error_message

    attribute :started_at do |history|
      history.started_at&.iso8601
    end

    attribute :completed_at do |history|
      history.completed_at&.iso8601
    end

    attribute :duration_formatted do |history|
      history.duration_formatted
    end

    attribute :successful do |history|
      history.successful?
    end
  end

  # Detail variant - includes audit entries
  class Detail
    include Alba::Resource

    attributes :id, :plugin_name, :status,
               :records_processed, :records_created, :records_updated,
               :error_message

    attribute :started_at do |history|
      history.started_at&.iso8601
    end

    attribute :completed_at do |history|
      history.completed_at&.iso8601
    end

    attribute :duration do |history|
      history.duration
    end

    attribute :duration_formatted do |history|
      history.duration_formatted
    end

    attribute :successful do |history|
      history.successful?
    end

    attribute :audit_entries do |history|
      DataAuditLog.for_sync(history.id).order(created_at: :asc).map(&:summary)
    end
  end
end
