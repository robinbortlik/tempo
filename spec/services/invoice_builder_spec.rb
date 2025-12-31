require 'rails_helper'

RSpec.describe InvoiceBuilder do
  let(:client) { create(:client, hourly_rate: 100, currency: "EUR", payment_terms: "Net 30 days") }
  let(:project) { create(:project, client: client, hourly_rate: 100) }
  let(:period_start) { Date.new(2024, 12, 1) }
  let(:period_end) { Date.new(2024, 12, 31) }

  describe "#initialize" do
    it "accepts client_id, period_start, and period_end" do
      builder = described_class.new(
        client_id: client.id,
        period_start: period_start,
        period_end: period_end
      )

      expect(builder.client).to eq(client)
      expect(builder.period_start).to eq(period_start)
      expect(builder.period_end).to eq(period_end)
    end

    it "accepts string dates" do
      builder = described_class.new(
        client_id: client.id,
        period_start: "2024-12-01",
        period_end: "2024-12-31"
      )

      expect(builder.period_start).to eq(Date.new(2024, 12, 1))
      expect(builder.period_end).to eq(Date.new(2024, 12, 31))
    end

    it "sets default issue_date to current date" do
      builder = described_class.new(
        client_id: client.id,
        period_start: period_start,
        period_end: period_end
      )

      expect(builder.issue_date).to eq(Date.current)
    end

    it "calculates default due_date from payment terms" do
      builder = described_class.new(
        client_id: client.id,
        period_start: period_start,
        period_end: period_end,
        issue_date: Date.new(2024, 12, 29)
      )

      expect(builder.due_date).to eq(Date.new(2025, 1, 28))
    end

    it "raises error for non-existent client" do
      expect {
        described_class.new(
          client_id: 99999,
          period_start: period_start,
          period_end: period_end
        )
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "#unbilled_entries" do
    it "returns unbilled work entries for the client within date range" do
      entry1 = create(:work_entry, project: project, date: Date.new(2024, 12, 15), status: :unbilled)
      entry2 = create(:work_entry, project: project, date: Date.new(2024, 12, 20), status: :unbilled)
      # Entry outside range
      create(:work_entry, project: project, date: Date.new(2025, 1, 5), status: :unbilled)
      # Invoiced entry (should be excluded)
      create(:work_entry, project: project, date: Date.new(2024, 12, 10), status: :invoiced)

      builder = described_class.new(
        client_id: client.id,
        period_start: period_start,
        period_end: period_end
      )

      expect(builder.unbilled_entries).to contain_exactly(entry1, entry2)
    end

    it "excludes entries from other clients" do
      other_client = create(:client)
      other_project = create(:project, client: other_client)
      create(:work_entry, project: other_project, date: Date.new(2024, 12, 15), status: :unbilled)
      entry = create(:work_entry, project: project, date: Date.new(2024, 12, 15), status: :unbilled)

      builder = described_class.new(
        client_id: client.id,
        period_start: period_start,
        period_end: period_end
      )

      expect(builder.unbilled_entries).to contain_exactly(entry)
    end

    it "returns entries ordered by date ascending" do
      entry1 = create(:work_entry, project: project, date: Date.new(2024, 12, 20), status: :unbilled)
      entry2 = create(:work_entry, project: project, date: Date.new(2024, 12, 10), status: :unbilled)
      entry3 = create(:work_entry, project: project, date: Date.new(2024, 12, 15), status: :unbilled)

      builder = described_class.new(
        client_id: client.id,
        period_start: period_start,
        period_end: period_end
      )

      expect(builder.unbilled_entries).to eq([entry2, entry3, entry1])
    end
  end

  describe "#total_hours" do
    it "sums hours from unbilled time entries" do
      create(:work_entry, :time_entry, project: project, date: Date.new(2024, 12, 15), hours: 8, status: :unbilled)
      create(:work_entry, :time_entry, project: project, date: Date.new(2024, 12, 16), hours: 4, status: :unbilled)

      builder = described_class.new(
        client_id: client.id,
        period_start: period_start,
        period_end: period_end
      )

      expect(builder.total_hours).to eq(12)
    end

    it "ignores fixed entries when calculating hours" do
      create(:work_entry, :time_entry, project: project, date: Date.new(2024, 12, 15), hours: 8, status: :unbilled)
      create(:work_entry, :fixed_entry, project: project, date: Date.new(2024, 12, 16), amount: 500, status: :unbilled)

      builder = described_class.new(
        client_id: client.id,
        period_start: period_start,
        period_end: period_end
      )

      expect(builder.total_hours).to eq(8)
    end

    it "returns 0 when no entries exist" do
      builder = described_class.new(
        client_id: client.id,
        period_start: period_start,
        period_end: period_end
      )

      expect(builder.total_hours).to eq(0)
    end
  end

  describe "#total_amount" do
    it "sums calculated amounts from unbilled entries including fixed" do
      create(:work_entry, :time_entry, project: project, date: Date.new(2024, 12, 15), hours: 8, status: :unbilled)
      create(:work_entry, :fixed_entry, project: project, date: Date.new(2024, 12, 16), amount: 500, status: :unbilled)

      builder = described_class.new(
        client_id: client.id,
        period_start: period_start,
        period_end: period_end
      )

      # 8 * 100 + 500 = 1300
      expect(builder.total_amount).to eq(1300)
    end
  end

  describe "#preview" do
    before do
      create(:work_entry, :time_entry, project: project, date: Date.new(2024, 12, 15), hours: 8, description: "Work", status: :unbilled)
    end

    it "returns preview data structure with line_items" do
      builder = described_class.new(
        client_id: client.id,
        period_start: period_start,
        period_end: period_end,
        issue_date: Date.new(2024, 12, 29)
      )

      preview = builder.preview

      expect(preview[:client][:id]).to eq(client.id)
      expect(preview[:client][:name]).to eq(client.name)
      expect(preview[:period_start]).to eq(period_start)
      expect(preview[:period_end]).to eq(period_end)
      expect(preview[:total_hours]).to eq(8)
      expect(preview[:total_amount]).to eq(800)
      expect(preview[:currency]).to eq("EUR")
      expect(preview[:line_items]).to be_an(Array)
      expect(preview[:line_items].first[:line_type]).to eq("time_aggregate")
    end

    it "aggregates time entries by project" do
      create(:work_entry, :time_entry, project: project, date: Date.new(2024, 12, 16), hours: 4, status: :unbilled)

      builder = described_class.new(
        client_id: client.id,
        period_start: period_start,
        period_end: period_end
      )

      preview = builder.preview

      # Should have one aggregated line item for the project
      expect(preview[:line_items].count).to eq(1)
      expect(preview[:line_items].first[:quantity]).to eq(12) # 8 + 4
    end

    it "shows fixed entries as individual line items" do
      create(:work_entry, :fixed_entry, project: project, date: Date.new(2024, 12, 16), amount: 500, description: "Setup fee", status: :unbilled)

      builder = described_class.new(
        client_id: client.id,
        period_start: period_start,
        period_end: period_end
      )

      preview = builder.preview

      expect(preview[:line_items].count).to eq(2) # 1 time aggregate + 1 fixed
      fixed_item = preview[:line_items].find { |i| i[:line_type] == "fixed" }
      expect(fixed_item[:amount]).to eq(500)
      expect(fixed_item[:description]).to eq("Setup fee")
    end

    it "includes work entry IDs" do
      builder = described_class.new(
        client_id: client.id,
        period_start: period_start,
        period_end: period_end
      )

      preview = builder.preview

      expect(preview[:work_entry_ids]).to be_an(Array)
      expect(preview[:work_entry_ids].length).to eq(1)
    end
  end

  describe "#create_draft" do
    context "with unbilled entries" do
      before do
        create(:work_entry, :time_entry, project: project, date: Date.new(2024, 12, 15), hours: 8, status: :unbilled)
        create(:work_entry, :time_entry, project: project, date: Date.new(2024, 12, 16), hours: 4, status: :unbilled)
      end

      it "creates a draft invoice" do
        builder = described_class.new(
          client_id: client.id,
          period_start: period_start,
          period_end: period_end,
          issue_date: Date.new(2024, 12, 29),
          notes: "Thank you!"
        )

        expect { builder.create_draft }.to change(Invoice, :count).by(1)

        result = builder.create_draft
        expect(result[:success]).to be true
      end

      it "creates InvoiceLineItems and links work entries" do
        builder = described_class.new(
          client_id: client.id,
          period_start: period_start,
          period_end: period_end
        )

        result = builder.create_draft
        invoice = result[:invoice]

        expect(invoice.line_items.count).to eq(1) # Aggregated into one
        expect(invoice.line_items.first.line_type).to eq("time_aggregate")
        expect(invoice.line_items.first.work_entries.count).to eq(2)
      end

      it "marks work entries as invoiced" do
        builder = described_class.new(
          client_id: client.id,
          period_start: period_start,
          period_end: period_end
        )

        builder.create_draft

        expect(WorkEntry.invoiced.count).to eq(2)
      end

      it "sets invoice attributes correctly" do
        builder = described_class.new(
          client_id: client.id,
          period_start: period_start,
          period_end: period_end,
          issue_date: Date.new(2024, 12, 29),
          due_date: Date.new(2025, 1, 28),
          notes: "Thank you!"
        )

        result = builder.create_draft
        invoice = result[:invoice]

        expect(invoice.client).to eq(client)
        expect(invoice.status).to eq("draft")
        expect(invoice.issue_date).to eq(Date.new(2024, 12, 29))
        expect(invoice.due_date).to eq(Date.new(2025, 1, 28))
        expect(invoice.period_start).to eq(period_start)
        expect(invoice.period_end).to eq(period_end)
        expect(invoice.currency).to eq("EUR")
        expect(invoice.notes).to eq("Thank you!")
      end

      it "calculates totals after creation" do
        builder = described_class.new(
          client_id: client.id,
          period_start: period_start,
          period_end: period_end
        )

        result = builder.create_draft
        invoice = result[:invoice]

        expect(invoice.total_hours).to eq(12)
        expect(invoice.total_amount).to eq(1200)
      end

      it "generates an invoice number" do
        builder = described_class.new(
          client_id: client.id,
          period_start: period_start,
          period_end: period_end
        )

        result = builder.create_draft
        invoice = result[:invoice]

        expect(invoice.number).to match(/\d{4}-\d{3}/)
      end
    end

    context "with mixed entry types" do
      before do
        create(:work_entry, :time_entry, project: project, date: Date.new(2024, 12, 15), hours: 8, status: :unbilled)
        create(:work_entry, :fixed_entry, project: project, date: Date.new(2024, 12, 16), amount: 500, description: "Setup", status: :unbilled)
      end

      it "creates separate line items for time aggregate and fixed" do
        builder = described_class.new(
          client_id: client.id,
          period_start: period_start,
          period_end: period_end
        )

        result = builder.create_draft
        invoice = result[:invoice]

        expect(invoice.line_items.count).to eq(2)
        expect(invoice.line_items.time_aggregate.count).to eq(1)
        expect(invoice.line_items.fixed.count).to eq(1)
      end
    end

    context "without unbilled entries" do
      it "returns an error" do
        builder = described_class.new(
          client_id: client.id,
          period_start: period_start,
          period_end: period_end
        )

        result = builder.create_draft

        expect(result[:success]).to be false
        expect(result[:errors]).to include("No unbilled work entries found for the specified period")
      end

      it "does not create an invoice" do
        builder = described_class.new(
          client_id: client.id,
          period_start: period_start,
          period_end: period_end
        )

        expect { builder.create_draft }.not_to change(Invoice, :count)
      end
    end
  end
end
