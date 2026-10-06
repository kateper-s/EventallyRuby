class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { visitor: 0, organizer: 1 }, validate: true

  has_many :organized_events, class_name: "Event", foreign_key: :organizer_id,
                              inverse_of: :organizer, dependent: :destroy

  has_many :orders, dependent: :destroy
  has_many :tickets, through: :orders

  validates :name, presence: true, length: { maximum: 60 }
end
