class TicketType < ApplicationRecord
  belongs_to :event, inverse_of: :ticket_types
  has_many :tickets, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 60 }, uniqueness: { scope: :event_id }
  validates :price, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :quota, numericality: { only_integer: true, greater_than: 0 }
  validates :sold_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :sold_count_within_quota

  after_update_commit :broadcast_availability, if: :saved_change_to_sold_count?

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

  def broadcast_availability
    broadcast_replace_to event, target: ActionView::RecordIdentifier.dom_id(self, :availability),
                                partial: "ticket_types/availability", locals: { ticket_type: self }
    broadcast_replace_to event, :sales, target: "sales",
                                partial: "events/sales", locals: { event: Event.includes(:ticket_types).find(event_id) }
  end

  def sold_count_within_quota
    return if quota.blank? || sold_count.blank?

    errors.add(:quota, :below_sold, count: sold_count) if sold_count > quota
  end
end
