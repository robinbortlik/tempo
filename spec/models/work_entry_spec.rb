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
end
