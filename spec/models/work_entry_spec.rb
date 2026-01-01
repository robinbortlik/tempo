require 'rails_helper'

RSpec.describe WorkEntry, type: :model do
  describe "entry_type auto-detection" do
    let(:project) { create(:project) }

    it "sets entry_type to time when only hours provided" do
      entry = build(:work_entry, project: project, hours: 8, amount: nil)
      entry.valid?
      expect(entry.entry_type).to eq("time")
    end

    it "sets entry_type to fixed when only amount provided" do
      entry = build(:work_entry, project: project, hours: nil, amount: 500)
      entry.valid?
      expect(entry.entry_type).to eq("fixed")
    end

    it "sets entry_type to time when both hours and amount provided (custom pricing)" do
      entry = build(:work_entry, project: project, hours: 8, amount: 1200)
      entry.valid?
      expect(entry.entry_type).to eq("time")
    end
  end

  describe "validations" do
    let(:project) { create(:project) }

    it "requires at least one of hours or amount" do
      entry = build(:work_entry, project: project, hours: nil, amount: nil)
      expect(entry).not_to be_valid
      expect(entry.errors[:base]).to include("Either hours or amount must be provided")
    end

    it "is valid with only hours" do
      entry = build(:work_entry, project: project, hours: 8, amount: nil)
      expect(entry).to be_valid
    end

    it "is valid with only amount" do
      entry = build(:work_entry, project: project, hours: nil, amount: 500)
      expect(entry).to be_valid
    end

    it "is valid with both hours and amount" do
      entry = build(:work_entry, project: project, hours: 8, amount: 1200)
      expect(entry).to be_valid
    end

    it "requires date to be present" do
      entry = build(:work_entry, date: nil)
      expect(entry).not_to be_valid
      expect(entry.errors[:date]).to include("can't be blank")
    end

    it "requires hours to be greater than 0 when present" do
      entry = build(:work_entry, project: project, hours: 0, amount: nil)
      expect(entry).not_to be_valid
      expect(entry.errors[:hours]).to include("must be greater than 0")
    end
  end

  describe "#calculated_amount" do
    let(:client) { create(:client, hourly_rate: 100) }
    let(:project) { create(:project, client: client, hourly_rate: 120) }

    context "with custom amount set" do
      it "returns the custom amount instead of calculated" do
        entry = create(:work_entry, project: project, hours: 8, amount: 1500)
        expect(entry.calculated_amount).to eq(1500)
      end
    end

    context "without custom amount" do
      it "calculates amount from hours and project rate" do
        entry = create(:work_entry, project: project, hours: 8, amount: nil)
        expect(entry.calculated_amount).to eq(960)  # 8 * 120
      end
    end

    context "for fixed entries" do
      it "returns the fixed amount" do
        entry = create(:work_entry, :fixed_entry, project: project, amount: 500)
        expect(entry.calculated_amount).to eq(500)
      end
    end
  end

  describe "scopes" do
    describe ".by_entry_type" do
      let!(:time_entry) { create(:work_entry, :time_entry) }
      let!(:fixed_entry) { create(:work_entry, :fixed_entry) }

      it "returns only time entries when filtering by time" do
        expect(WorkEntry.by_entry_type(:time)).to contain_exactly(time_entry)
      end

      it "returns only fixed entries when filtering by fixed" do
        expect(WorkEntry.by_entry_type(:fixed)).to contain_exactly(fixed_entry)
      end
    end
  end

  describe "associations" do
    it "belongs to a project" do
      association = described_class.reflect_on_association(:project)
      expect(association.macro).to eq(:belongs_to)
    end

    it "has many invoice_line_items through join table" do
      association = described_class.reflect_on_association(:invoice_line_items)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:invoice_line_item_work_entries)
    end
  end

  describe "hourly_rate auto-population" do
    let(:client) { create(:client, hourly_rate: 100) }
    let(:project) { create(:project, client: client, hourly_rate: 120) }

    it "auto-populates hourly_rate from project.effective_hourly_rate on create" do
      entry = create(:work_entry, project: project, hours: 8, amount: nil)
      expect(entry.hourly_rate).to eq(120)
    end

    it "preserves user-provided hourly_rate and does not overwrite" do
      entry = create(:work_entry, project: project, hours: 8, amount: nil, hourly_rate: 150)
      expect(entry.hourly_rate).to eq(150)
    end

    it "only populates hourly_rate for time-based entries, not fixed" do
      entry = create(:work_entry, :fixed_entry, project: project)
      expect(entry.hourly_rate).to be_nil
    end
  end

  describe "#calculated_amount with stored hourly_rate" do
    let(:client) { create(:client, hourly_rate: 100) }
    let(:project) { create(:project, client: client, hourly_rate: 120) }

    it "uses stored hourly_rate when present" do
      entry = create(:work_entry, project: project, hours: 8, amount: nil, hourly_rate: 200)
      expect(entry.calculated_amount).to eq(1600) # 8 * 200
    end

    it "falls back to project rate when hourly_rate is null" do
      entry = build(:work_entry, project: project, hours: 8, amount: nil)
      entry.hourly_rate = nil
      entry.save!(validate: false) # Skip callback to force null hourly_rate
      entry.reload
      expect(entry.hourly_rate).to be_nil
      expect(entry.calculated_amount).to eq(960) # 8 * 120 (project rate)
    end
  end

  describe "hourly_rate validation on invoiced entries" do
    let(:project) { create(:project) }

    it "prevents hourly_rate change on invoiced entries" do
      entry = create(:work_entry, project: project, hours: 8, hourly_rate: 100)
      entry.update!(status: :invoiced)
      entry.hourly_rate = 150
      expect(entry).not_to be_valid
      expect(entry.errors[:hourly_rate]).to include("cannot be changed on invoiced entries")
    end
  end

  describe "hourly_rate mandatory for time entries" do
    it "requires hourly_rate to be present for time entries when project has no rate" do
      client = create(:client, hourly_rate: nil)
      project = create(:project, client: client, hourly_rate: nil)
      entry = build(:work_entry, project: project, hours: 8)
      # Callback can't populate rate because project has none
      expect(entry).not_to be_valid
      expect(entry.errors[:hourly_rate]).to include("can't be blank")
    end

    it "requires hourly_rate to be greater than 0 for time entries" do
      project = create(:project)
      entry = build(:work_entry, project: project, hours: 8, hourly_rate: 0)
      expect(entry).not_to be_valid
      expect(entry.errors[:hourly_rate]).to include("must be greater than 0")
    end

    it "does not require hourly_rate for fixed entries" do
      project = create(:project)
      entry = build(:work_entry, :fixed_entry, project: project, hourly_rate: nil)
      expect(entry).to be_valid
    end

    it "auto-populates hourly_rate from project for valid time entries" do
      client = create(:client, hourly_rate: 100)
      project = create(:project, client: client, hourly_rate: 150)
      entry = create(:work_entry, project: project, hours: 8)
      expect(entry.hourly_rate).to eq(150)
      expect(entry).to be_valid
    end
  end

  describe "hourly_rate persistence integration" do
    let(:client) { create(:client, hourly_rate: 100) }
    let(:project) { create(:project, client: client, hourly_rate: 120) }

    it "preserves entry amount when project rate changes after creation" do
      # Create entry - captures rate at time of creation
      entry = create(:work_entry, project: project, hours: 8, amount: nil)
      expect(entry.hourly_rate).to eq(120)
      expect(entry.calculated_amount).to eq(960)

      # Change project rate
      project.update!(hourly_rate: 200)

      # Entry should still use original stored rate
      entry.reload
      expect(entry.hourly_rate).to eq(120)
      expect(entry.calculated_amount).to eq(960)
    end

    it "preserves custom rate override when entry is updated" do
      # Create entry with custom rate
      entry = create(:work_entry, project: project, hours: 8, amount: nil, hourly_rate: 150)
      expect(entry.hourly_rate).to eq(150)

      # Update entry description (not the rate)
      entry.update!(description: "Updated description")

      # Custom rate should be preserved
      entry.reload
      expect(entry.hourly_rate).to eq(150)
      expect(entry.calculated_amount).to eq(1200)
    end
  end
end
