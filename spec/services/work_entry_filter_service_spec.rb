require 'rails_helper'

RSpec.describe WorkEntryFilterService do
  let(:client) { create(:client) }
  let(:project) { create(:project, client: client) }

  describe "#filter" do
    it "returns all entries when no filters applied" do
      entry1 = create(:work_entry, project: project, date: Date.current)
      entry2 = create(:work_entry, project: project, date: Date.yesterday)

      service = described_class.new(params: {})
      result = service.filter

      expect(result).to include(entry1, entry2)
    end

    it "orders by date descending" do
      old_entry = create(:work_entry, project: project, date: 1.week.ago)
      new_entry = create(:work_entry, project: project, date: Date.current)

      service = described_class.new(params: {})
      result = service.filter

      expect(result.first).to eq(new_entry)
      expect(result.last).to eq(old_entry)
    end

    context "date range filtering" do
      it "filters by start_date and end_date" do
        in_range = create(:work_entry, project: project, date: Date.current)
        before_range = create(:work_entry, project: project, date: 1.month.ago)
        after_range = create(:work_entry, project: project, date: 1.month.from_now)

        service = described_class.new(params: {
          start_date: 1.week.ago.to_s,
          end_date: 1.week.from_now.to_s
        })
        result = service.filter

        expect(result).to include(in_range)
        expect(result).not_to include(before_range, after_range)
      end

      it "filters by start_date only" do
        recent = create(:work_entry, project: project, date: Date.current)
        old = create(:work_entry, project: project, date: 1.month.ago)

        service = described_class.new(params: { start_date: 1.week.ago.to_s })
        result = service.filter

        expect(result).to include(recent)
        expect(result).not_to include(old)
      end

      it "filters by end_date only" do
        old = create(:work_entry, project: project, date: 1.week.ago)
        future = create(:work_entry, project: project, date: 1.month.from_now)

        service = described_class.new(params: { end_date: Date.current.to_s })
        result = service.filter

        expect(result).to include(old)
        expect(result).not_to include(future)
      end
    end

    context "client filtering" do
      it "filters by client_id" do
        other_client = create(:client)
        other_project = create(:project, client: other_client)

        matching = create(:work_entry, project: project)
        non_matching = create(:work_entry, project: other_project)

        service = described_class.new(params: { client_id: client.id })
        result = service.filter

        expect(result).to include(matching)
        expect(result).not_to include(non_matching)
      end
    end

    context "project filtering" do
      it "filters by project_id" do
        other_project = create(:project, client: client)

        matching = create(:work_entry, project: project)
        non_matching = create(:work_entry, project: other_project)

        service = described_class.new(params: { project_id: project.id })
        result = service.filter

        expect(result).to include(matching)
        expect(result).not_to include(non_matching)
      end
    end

    context "entry type filtering" do
      it "filters by entry_type" do
        time_entry = create(:work_entry, :time_entry, project: project)
        fixed_entry = create(:work_entry, :fixed_entry, project: project)

        service = described_class.new(params: { entry_type: 'time' })
        result = service.filter

        expect(result).to include(time_entry)
        expect(result).not_to include(fixed_entry)
      end
    end

    it "accepts custom scope" do
      entry1 = create(:work_entry, project: project, status: :unbilled)
      entry2 = create(:work_entry, project: project, status: :invoiced)

      service = described_class.new(scope: WorkEntry.unbilled, params: {})
      result = service.filter

      expect(result).to include(entry1)
      expect(result).not_to include(entry2)
    end
  end

  describe "#filter with year/month params" do
    context "year filtering" do
      it "filters by year only (all months in year)" do
        entry_2026 = create(:work_entry, project: project, date: Date.new(2026, 6, 15))
        entry_2025 = create(:work_entry, project: project, date: Date.new(2025, 3, 10))

        service = described_class.new(params: { year: 2026 })
        result = service.filter

        expect(result).to include(entry_2026)
        expect(result).not_to include(entry_2025)
      end
    end

    context "year and month filtering" do
      it "filters by year and specific month" do
        entry_jan = create(:work_entry, project: project, date: Date.new(2026, 1, 15))
        entry_feb = create(:work_entry, project: project, date: Date.new(2026, 2, 10))
        entry_jan_diff_year = create(:work_entry, project: project, date: Date.new(2025, 1, 20))

        service = described_class.new(params: { year: 2026, month: 1 })
        result = service.filter

        expect(result).to include(entry_jan)
        expect(result).not_to include(entry_feb, entry_jan_diff_year)
      end
    end

    context "default behavior" do
      it "defaults to current month when no params provided" do
        current_month_entry = create(:work_entry, project: project, date: Date.current)
        last_month_entry = create(:work_entry, project: project, date: Date.current - 1.month)

        service = described_class.new(params: {})
        result = service.filter

        expect(result).to include(current_month_entry)
        expect(result).not_to include(last_month_entry)
      end
    end

    context "backward compatibility" do
      it "uses start_date/end_date when provided (legacy behavior)" do
        in_range = create(:work_entry, project: project, date: Date.new(2026, 1, 15))
        out_of_range = create(:work_entry, project: project, date: Date.new(2026, 2, 15))

        service = described_class.new(params: {
          start_date: "2026-01-01",
          end_date: "2026-01-31"
        })
        result = service.filter

        expect(result).to include(in_range)
        expect(result).not_to include(out_of_range)
      end
    end
  end

  describe "#available_years" do
    it "returns years with work entries plus current year, sorted descending" do
      create(:work_entry, project: project, date: Date.new(2024, 5, 10))
      create(:work_entry, project: project, date: Date.new(2022, 3, 15))

      service = described_class.new(params: {})
      years = service.available_years

      expect(years).to include(2024, 2022, Date.current.year)
      expect(years).to eq(years.sort.reverse)
    end

    it "includes current year even without entries" do
      service = described_class.new(params: {})
      years = service.available_years

      expect(years).to include(Date.current.year)
    end

    it "returns unique years only" do
      create(:work_entry, project: project, date: Date.new(2024, 1, 10))
      create(:work_entry, project: project, date: Date.new(2024, 6, 15))

      service = described_class.new(params: {})
      years = service.available_years

      expect(years.count(2024)).to eq(1)
    end
  end

  describe "#summary" do
    it "returns total_hours for time entries" do
      create(:work_entry, :time_entry, project: project, hours: 8)
      create(:work_entry, :time_entry, project: project, hours: 4)

      service = described_class.new(params: {})

      expect(service.summary[:total_hours]).to eq(12.0)
    end

    it "returns total_amount for all entries" do
      create(:work_entry, :time_entry, project: project, hours: 10)
      create(:work_entry, :fixed_entry, project: project, amount: 500)

      service = described_class.new(params: {})

      expect(service.summary[:total_amount]).to eq(1500.0) # 10 * 100 + 500
    end

    it "returns time_entries_count" do
      create(:work_entry, :time_entry, project: project)
      create(:work_entry, :time_entry, project: project)
      create(:work_entry, :fixed_entry, project: project)

      service = described_class.new(params: {})

      expect(service.summary[:time_entries_count]).to eq(2)
    end

    it "returns fixed_entries_count" do
      create(:work_entry, :time_entry, project: project)
      create(:work_entry, :fixed_entry, project: project)
      create(:work_entry, :fixed_entry, project: project)

      service = described_class.new(params: {})

      expect(service.summary[:fixed_entries_count]).to eq(2)
    end

    it "respects applied filters in summary" do
      old_entry = create(:work_entry, project: project, hours: 8, date: 1.month.ago)
      recent_entry = create(:work_entry, project: project, hours: 4, date: Date.current)

      service = described_class.new(params: { start_date: 1.week.ago.to_s })

      expect(service.summary[:total_hours]).to eq(4.0)
    end
  end
end
