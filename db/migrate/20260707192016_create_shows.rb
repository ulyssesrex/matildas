class CreateShows < ActiveRecord::Migration[8.1]
  def change
    create_table :shows do |t|
      t.timestamp :time
      t.string :location
      t.string :price
      t.text :notes

      t.timestamps
    end
  end
end
