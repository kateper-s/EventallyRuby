class Ticket < ApplicationRecord
  class CheckInError < StandardError; end

  belongs_to :order
  belongs_to :ticket_type
  has_one :event, through: :ticket_type

  has_secure_token :code

  validates :price, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def checked_in?
    checked_in_at.present?
  end

  def check_in!(by:)
    raise CheckInError, "Нет прав на чекин этого события" unless by && event.organizer_id == by.id
    raise CheckInError, "Заказ не оплачен или отменён" unless order.paid?

    with_lock do
      raise CheckInError, "Билет уже использован" if checked_in?

      update!(checked_in_at: Time.current)
    end
  end
end
