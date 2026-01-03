class ProjectSerializer
  include Alba::Resource

  # Full detail - for show/edit pages
  attributes :id, :name, :client_id, :hourly_rate, :effective_hourly_rate, :active

  attribute :client_name do |project|
    project.client.name
  end

  attribute :client_currency do |project|
    project.client.currency
  end

  class List
    include Alba::Resource

    attributes :id, :name, :hourly_rate, :effective_hourly_rate, :active

    attribute :unbilled_hours do |project|
      params[:unbilled_stats]&.dig(project.id) || project.work_entries.unbilled.sum(:hours)
    end

    attribute :work_entries_count do |project|
      project.work_entries.size
    end
  end

  # Empty is a simple PORO since Alba doesn't handle nil objects
  class Empty
    DEFAULTS = {
      id: nil,
      name: "",
      client_id: nil,
      hourly_rate: nil,
      active: true
    }.freeze

    def self.to_h = DEFAULTS
    def self.serializable_hash = DEFAULTS
  end

  class ForClientShow
    include Alba::Resource

    attributes :id, :name, :hourly_rate, :effective_hourly_rate, :active

    attribute :unbilled_hours do |project|
      project.work_entries.time.unbilled.sum(:hours)
    end
  end

  class ForSelect
    include Alba::Resource
    attributes :id, :name, :effective_hourly_rate
  end

  class GroupedByClient
    include Alba::Resource

    attribute :client do |data|
      {
        id: data[:client].id,
        name: data[:client].name,
        currency: data[:client].currency
      }
    end

    attribute :projects do |data|
      data[:projects].map do |project|
        {
          id: project.id,
          name: project.name,
          hourly_rate: project.hourly_rate,
          effective_hourly_rate: project.effective_hourly_rate,
          active: project.active,
          unbilled_hours: params[:unbilled_stats]&.dig(project.id) || 0,
          work_entries_count: project.work_entries.size
        }
      end
    end
  end

  class GroupedByClientForForm
    include Alba::Resource

    attribute :client do |data|
      {
        id: data[:client].id,
        name: data[:client].name,
        currency: data[:client].currency
      }
    end

    attribute :projects do |data|
      data[:projects].map do |project|
        {
          id: project.id,
          name: project.name,
          effective_hourly_rate: project.effective_hourly_rate
        }
      end
    end
  end
end
