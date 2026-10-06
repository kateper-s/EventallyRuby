class CreateFavorites < ActiveRecord::Migration[7.1]
  def change
    create_table :favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.string :event_key, null: false

      t.timestamps
    end

    add_index :favorites, %i[user_id event_key], unique: true
  end
end
