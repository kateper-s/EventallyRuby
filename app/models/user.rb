class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { visitor: 0, organizer: 1 }

  validates :name, presence: true, length: { maximum: 60 }
end