class ReplaceLinksWithArtists < ActiveRecord::Migration[8.1]
  def up
    drop_join_table :shows, :links
    drop_table :links

    create_table :artists do |t|
      t.string :name, null: false
      t.string :url, null: false

      t.timestamps
    end

    create_join_table :artists, :shows do |t|
      t.index [ :artist_id, :show_id ], unique: true
      t.index [ :show_id, :artist_id ], unique: true
    end
  end

  def down
    drop_join_table :artists, :shows
    drop_table :artists

    create_table :links do |t|
      t.string :name
      t.string :url
      t.boolean :artist, default: false, null: false

      t.timestamps
    end

    create_join_table :shows, :links do |t|
      t.index [ :show_id, :link_id ]
      t.index [ :link_id, :show_id ]
    end
  end
end
