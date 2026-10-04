class TicketType < ApplicationRecord
  belongs_to :event, inverse_of: :ticket_types
  has_many :tickets, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 60 }, uniqueness: { scope: :event_id }
  validates :price, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :quota, numericality: { only_integer: true, greater_than: 0 }
  validates :sold_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :sold_count_within_quota

  def available
    quota.to_i - sold_count.to_i
  end

  def sold_out?
    available <= 0
  end

  def free?
    price.to_i.zero?
  end

  private

  def sold_count_within_quota
    return if quota.blank? || sold_count.blank?

    errors.add(:quota, :below_sold, count: sold_count) if sold_count > quota
  end
end
