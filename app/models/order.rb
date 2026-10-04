class Order < ApplicationRecord
  class PurchaseError < StandardError; end
  class SoldOut < PurchaseError; end
  class NotOnSale < PurchaseError; end

  belongs_to :user
  has_many :tickets, dependent: :destroy

  enum :status, { pending: 0, paid: 1, cancelled: 2 }, validate: true

  validates :total, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.purchase!(user:, ticket_type:, quantity: 1)
    quantity = Integer(quantity)
    raise ArgumentError, "quantity must be positive" unless quantity.positive?

    transaction do
      ticket_type.lock!
      event = ticket_type.event
      raise NotOnSale, "Продажа билетов закрыта" unless event.published? && !event.past?
      raise SoldOut, "Осталось мест: #{ticket_type.available}" if ticket_type.available < quantity

      order = user.orders.create!(status: :paid, total: ticket_type.price * quantity, paid_at: Time.current)
      quantity.times { order.tickets.create!(ticket_type: ticket_type, price: ticket_type.price) }
      ticket_type.update!(sold_count: ticket_type.sold_count + quantity)
      order
    end
  end

  def cancel!
    return self if cancelled?

    transaction do
      tickets.group_by(&:ticket_type).each do |ticket_type, type_tickets|
        ticket_type.lock!
        ticket_type.update!(sold_count: ticket_type.sold_count - type_tickets.size)
      end
      update!(status: :cancelled)
    end
    self
  end
end
