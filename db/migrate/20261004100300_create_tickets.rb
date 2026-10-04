class CreateTickets < ActiveRecord::Migration[7.1]
  def change
    create_table :tickets do |t|
      t.references :order, null: false, foreign_key: true
      t.references :ticket_type, null: false, foreign_key: true
      t.string :code, null: false
      t.integer :price, null: false
      t.datetime :checked_in_at

      t.timestamps
    end

    add_index :tickets, :code, unique: true
    add_check_constraint :tickets, "price >= 0", name: "tickets_price_non_negative"
  end
end
