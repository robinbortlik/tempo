require 'rails_helper'

RSpec.describe "BackfillHourlyRateToWorkEntries migration" do
  describe "data backfill" do
    let(:client) { create(:client, hourly_rate: 100) }
    let(:project_with_rate) { create(:project, client: client, hourly_rate: 120) }
    let(:project_without_rate) { create(:project, client: client, hourly_rate: nil) }

    def run_backfill
      # Simulate the backfill migration logic
      WorkEntry.where(hourly_rate: nil, entry_type: :time).find_in_batches(batch_size: 1000) do |batch|
        batch.each do |entry|
          entry.update_column(:hourly_rate, entry.project.effective_hourly_rate)
        end
      end
    end

    it "populates hourly_rate for existing time entries from project.effective_hourly_rate" do
      # Create time entries with null hourly_rate (simulating pre-migration state)
      entry1 = create(:work_entry, :time_entry, project: project_with_rate)
      entry1.update_column(:hourly_rate, nil)

      entry2 = create(:work_entry, :time_entry, project: project_without_rate)
      entry2.update_column(:hourly_rate, nil)

      # Verify hourly_rate is null before backfill
      expect(entry1.reload.hourly_rate).to be_nil
      expect(entry2.reload.hourly_rate).to be_nil

      # Run backfill
      run_backfill

      # Verify hourly_rate is populated from project.effective_hourly_rate
      expect(entry1.reload.hourly_rate).to eq(120) # project rate
      expect(entry2.reload.hourly_rate).to eq(100) # falls back to client rate
    end

    it "does not modify fixed entries (hourly_rate remains null)" do
      # Create a fixed entry
      fixed_entry = create(:work_entry, :fixed_entry, project: project_with_rate)

      # Verify hourly_rate is null
      expect(fixed_entry.hourly_rate).to be_nil

      # Run backfill
      run_backfill

      # Verify fixed entry is unchanged
      expect(fixed_entry.reload.hourly_rate).to be_nil
    end
  end
end
