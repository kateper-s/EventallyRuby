class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.references :organizer, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.string :category, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.string :venue, null: false
      t.string :city, null: false
      t.boolean :published, null: false, default: false

      t.timestamps
    end

    add_index :events, :starts_at
    add_index :events, :category
    add_check_constraint :events, "ends_at IS NULL OR ends_at > starts_at", name: "events_ends_after_starts"
  end
end
