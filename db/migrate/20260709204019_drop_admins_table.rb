class DropAdminsTable < ActiveRecord::Migration[8.1]
  def up
    drop_table :admins
  end

  def down
    create_table :admins do |t|
      t.string :username, null: false
      t.string :password_digest, null: false

      t.timestamps
    end

    add_index :admins, :username, unique: true
  end
end
