class SplitShowDateAndTime < ActiveRecord::Migration[8.1]
  class MigrationShow < ActiveRecord::Base
    self.table_name = "shows"
  end

  def up
    rename_column :shows, :time, :scheduled_at
    add_column :shows, :date, :date
    add_column :shows, :time, :time

    MigrationShow.reset_column_information
    MigrationShow.find_each do |show|
      eastern_time = show.scheduled_at&.in_time_zone("Eastern Time (US & Canada)")
      show.update_columns(
        date: eastern_time&.to_date,
        time: eastern_time&.strftime("%H:%M:%S")
      )
    end

    change_column_null :shows, :date, false
    remove_column :shows, :scheduled_at
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "A TBD show date cannot be represented by the former datetime column"
  end
end
