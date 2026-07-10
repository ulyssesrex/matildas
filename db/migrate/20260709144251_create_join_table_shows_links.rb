class CreateJoinTableShowsLinks < ActiveRecord::Migration[8.1]
  def change
    create_join_table :shows, :links do |t|
      t.index [ :show_id, :link_id ]
      t.index [ :link_id, :show_id ]
    end
  end
end
