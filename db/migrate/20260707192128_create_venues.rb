class CreateVenues < ActiveRecord::Migration[8.1]
  def change
    create_table :venues do |t|
      t.string :city
      t.string :state
      t.string :map_url
      t.string :name

      t.timestamps
    end
  end
end
