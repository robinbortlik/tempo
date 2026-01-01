class AddHourlyRateToWorkEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :work_entries, :hourly_rate, :decimal, precision: 10, scale: 2
  end
end
