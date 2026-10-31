class CreateComments < ActiveRecord::Migration[7.1]
  def change
    create_table :comments do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false

      t.timestamps
    end

    add_index :comments, %i[event_id created_at]
    add_check_constraint :comments, "char_length(body) BETWEEN 1 AND 1000", name: "comments_body_length"
  end
end
