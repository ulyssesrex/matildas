class CreateLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :links do |t|
      t.string :name
      t.string :url

      t.timestamps
    end
  end
end
