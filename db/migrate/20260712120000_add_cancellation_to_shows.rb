class AddCancellationToShows < ActiveRecord::Migration[8.1]
  def change
    add_column :shows, :cancelled, :boolean, default: false, null: false
    add_column :shows, :cancellation_notes, :text
  end
end
