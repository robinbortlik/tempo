class BackfillHourlyRateToWorkEntries < ActiveRecord::Migration[8.1]
  def up
    # Process entries in batches of 1000 to avoid memory issues
    # Only update time entries (entry_type = 0) where hourly_rate is NULL
    WorkEntry.where(hourly_rate: nil, entry_type: 0).find_in_batches(batch_size: 1000) do |batch|
      batch.each do |entry|
        entry.update_column(:hourly_rate, entry.project.effective_hourly_rate)
      end
    end
  end

  def down
    # Set hourly_rate back to null for all time entries
    WorkEntry.where(entry_type: 0).update_all(hourly_rate: nil)
  end
end
