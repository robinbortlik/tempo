require 'rails_helper'

RSpec.describe TimeEntry, type: :model do
  describe "associations" do
    it "belongs to a project" do
      association = described_class.reflect_on_association(:project)
      expect(association.macro).to eq(:belongs_to)
    end

    it "optionally belongs to an invoice" do
      association = described_class.reflect_on_association(:invoice)
      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:optional]).to be true
    end

    it "is destroyed when project is destroyed" do
      project = create(:project)
      time_entry = create(:time_entry, project: project)
      expect { project.destroy }.to change(TimeEntry, :count).by(-1)
    end
  end

  describe "validations" do
    subject { build(:time_entry) }

    it { is_expected.to be_valid }

    describe "date" do
      it "requires date to be present" do
        time_entry = build(:time_entry, date: nil)
        expect(time_entry).not_to be_valid
        expect(time_entry.errors[:date]).to include("can't be blank")
      end

      it "accepts valid dates" do
        time_entry = build(:time_entry, date: Date.current)
        expect(time_entry).to be_valid
      end

      it "accepts past dates" do
        time_entry = build(:time_entry, date: 1.month.ago.to_date)
        expect(time_entry).to be_valid
      end
    end

    describe "hours" do
      it "requires hours to be present" do
        time_entry = build(:time_entry, hours: nil)
        expect(time_entry).not_to be_valid
        expect(time_entry.errors[:hours]).to include("can't be blank")
      end

      it "requires hours to be greater than 0" do
        time_entry = build(:time_entry, hours: 0)
        expect(time_entry).not_to be_valid
        expect(time_entry.errors[:hours]).to include("must be greater than 0")
      end

      it "rejects negative hours" do
        time_entry = build(:time_entry, hours: -5)
        expect(time_entry).not_to be_valid
        expect(time_entry.errors[:hours]).to include("must be greater than 0")
      end

      it "accepts positive hours" do
        time_entry = build(:time_entry, hours: 8)
        expect(time_entry).to be_valid
      end

      it "accepts decimal hours" do
        time_entry = build(:time_entry, hours: 4.5)
        expect(time_entry).to be_valid
      end

      it "accepts fractional hours" do
        time_entry = build(:time_entry, hours: 0.25)
        expect(time_entry).to be_valid
      end
    end

    describe "description" do
      it "allows empty description" do
        time_entry = build(:time_entry, description: nil)
        expect(time_entry).to be_valid
      end

      it "allows description with text" do
        time_entry = build(:time_entry, description: "Working on API integration")
        expect(time_entry).to be_valid
      end
    end

    describe "project" do
      it "requires a project" do
        time_entry = build(:time_entry)
        time_entry.project = nil
        expect(time_entry).not_to be_valid
        expect(time_entry.errors[:project]).to include("must exist")
      end
    end
  end

  describe "enum status" do
    it "defines unbilled and invoiced statuses" do
      expect(TimeEntry.statuses).to eq({ "unbilled" => 0, "invoiced" => 1 })
    end

    it "defaults to unbilled" do
      time_entry = TimeEntry.new
      expect(time_entry.unbilled?).to be true
    end

    it "can be set to invoiced" do
      time_entry = build(:time_entry, status: :invoiced)
      expect(time_entry.invoiced?).to be true
    end

    it "provides scope methods for unbilled" do
      unbilled = create(:time_entry, :unbilled)
      invoiced = create(:time_entry, :invoiced)
      expect(TimeEntry.unbilled).to contain_exactly(unbilled)
    end

    it "provides scope methods for invoiced" do
      unbilled = create(:time_entry, :unbilled)
      invoiced = create(:time_entry, :invoiced)
      expect(TimeEntry.invoiced).to contain_exactly(invoiced)
    end
  end

  describe "scopes" do
    describe ".for_date_range" do
      let!(:old_entry) { create(:time_entry, date: 2.weeks.ago.to_date) }
      let!(:entry_in_range) { create(:time_entry, date: 3.days.ago.to_date) }
      let!(:recent_entry) { create(:time_entry, date: Date.current) }
      let!(:future_entry) { create(:time_entry, date: 1.week.from_now.to_date) }

      it "returns entries within the specified date range" do
        start_date = 1.week.ago.to_date
        end_date = Date.current
        result = TimeEntry.for_date_range(start_date, end_date)
        expect(result).to contain_exactly(entry_in_range, recent_entry)
      end

      it "includes entries on the start date" do
        start_date = 3.days.ago.to_date
        end_date = Date.current
        result = TimeEntry.for_date_range(start_date, end_date)
        expect(result).to include(entry_in_range)
      end

      it "includes entries on the end date" do
        start_date = 3.days.ago.to_date
        end_date = Date.current
        result = TimeEntry.for_date_range(start_date, end_date)
        expect(result).to include(recent_entry)
      end

      it "excludes entries outside the range" do
        start_date = 1.week.ago.to_date
        end_date = Date.current
        result = TimeEntry.for_date_range(start_date, end_date)
        expect(result).not_to include(old_entry)
        expect(result).not_to include(future_entry)
      end

      it "returns empty collection when no entries in range" do
        start_date = 1.year.ago.to_date
        end_date = 11.months.ago.to_date
        result = TimeEntry.for_date_range(start_date, end_date)
        expect(result).to be_empty
      end
    end
  end

  describe "#calculated_amount" do
    let(:client) { create(:client, hourly_rate: 120.00) }
    let(:project_with_rate) { create(:project, client: client, hourly_rate: 150.00) }
    let(:project_without_rate) { create(:project, client: client, hourly_rate: nil) }

    context "when project has its own hourly rate" do
      it "calculates amount using project's rate" do
        time_entry = create(:time_entry, project: project_with_rate, hours: 8)
        expect(time_entry.calculated_amount).to eq(1200.00)
      end

      it "handles decimal hours correctly" do
        time_entry = create(:time_entry, project: project_with_rate, hours: 2.5)
        expect(time_entry.calculated_amount).to eq(375.00)
      end
    end

    context "when project falls back to client rate" do
      it "calculates amount using client's rate" do
        time_entry = create(:time_entry, project: project_without_rate, hours: 8)
        expect(time_entry.calculated_amount).to eq(960.00)
      end
    end

    context "when neither project nor client has hourly rate" do
      let(:client_without_rate) { create(:client, hourly_rate: nil) }
      let(:project_without_any_rate) { create(:project, client: client_without_rate, hourly_rate: nil) }

      it "returns nil" do
        time_entry = create(:time_entry, project: project_without_any_rate, hours: 8)
        expect(time_entry.calculated_amount).to be_nil
      end
    end

    context "with edge cases" do
      it "returns nil when hours is nil" do
        time_entry = build(:time_entry, project: project_with_rate, hours: 8)
        allow(time_entry).to receive(:hours).and_return(nil)
        expect(time_entry.calculated_amount).to be_nil
      end

      it "handles zero as project rate" do
        project_zero_rate = create(:project, client: client, hourly_rate: 0)
        time_entry = create(:time_entry, project: project_zero_rate, hours: 8)
        expect(time_entry.calculated_amount).to eq(0)
      end
    end
  end

  describe "default values" do
    it "defaults status to unbilled" do
      time_entry = TimeEntry.new
      expect(time_entry.status).to eq("unbilled")
    end
  end

  describe "factory" do
    it "creates a valid time_entry" do
      time_entry = build(:time_entry)
      expect(time_entry).to be_valid
    end

    it "creates a time_entry with associated project" do
      time_entry = create(:time_entry)
      expect(time_entry.project).to be_present
    end

    it "creates an invoiced time_entry with trait" do
      time_entry = build(:time_entry, :invoiced)
      expect(time_entry.invoiced?).to be true
    end

    it "creates an unbilled time_entry with trait" do
      time_entry = build(:time_entry, :unbilled)
      expect(time_entry.unbilled?).to be true
    end

    it "creates a time_entry with yesterday's date" do
      time_entry = build(:time_entry, :yesterday)
      expect(time_entry.date).to eq(Date.yesterday)
    end

    it "creates a time_entry with custom hours" do
      time_entry = build(:time_entry, :with_custom_hours, custom_hours: 4.5)
      expect(time_entry.hours).to eq(4.5)
    end

    it "creates a time_entry without description" do
      time_entry = build(:time_entry, :without_description)
      expect(time_entry.description).to be_nil
    end
  end
end
