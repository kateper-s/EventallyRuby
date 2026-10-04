class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.integer :total, null: false, default: 0
      t.datetime :paid_at

      t.timestamps
    end

    add_index :orders, :status
    add_check_constraint :orders, "total >= 0", name: "orders_total_non_negative"
  end
end
