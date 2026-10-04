class CreateTicketTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :ticket_types do |t|
      t.references :event, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :price, null: false, default: 0
      t.integer :quota, null: false
      t.integer :sold_count, null: false, default: 0

      t.timestamps
    end

    add_index :ticket_types, [:event_id, :name], unique: true
    add_check_constraint :ticket_types, "price >= 0", name: "ticket_types_price_non_negative"
    add_check_constraint :ticket_types, "quota > 0", name: "ticket_types_quota_positive"
    add_check_constraint :ticket_types, "sold_count >= 0 AND sold_count <= quota", name: "ticket_types_sold_within_quota"
  end
end
