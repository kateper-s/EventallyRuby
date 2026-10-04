require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "purchase! создаёт оплаченный заказ с билетами" do
    type = ticket_types(:conf_standard)

    order = nil
    assert_difference -> { Ticket.count }, 3 do
      order = Order.purchase!(user: users(:ivan), ticket_type: type, quantity: 3)
    end

    assert order.paid?
    assert_not_nil order.paid_at
    assert_equal 3 * 4900, order.total
    assert_equal [4900], order.tickets.map(&:price).uniq
    assert_equal 5, type.reload.sold_count
  end

  test "у каждого билета уникальный код" do
    order = Order.purchase!(user: users(:ivan), ticket_type: ticket_types(:meetup_free), quantity: 5)
    codes = order.tickets.map(&:code)
    assert_equal 5, codes.uniq.size
    assert codes.all?(&:present?)
  end

  test "нельзя купить больше, чем осталось мест" do
    type = ticket_types(:conf_vip)
    assert_no_difference -> { Order.count } do
      assert_raises(Order::SoldOut) do
        Order.purchase!(user: users(:ivan), ticket_type: type)
      end
    end
    assert_equal 1, type.reload.sold_count
  end

  test "при нехватке мест заказ не создаётся частично" do
    type = ticket_types(:conf_standard)
    assert_no_difference -> { Ticket.count } do
      assert_raises(Order::SoldOut) do
        Order.purchase!(user: users(:ivan), ticket_type: type, quantity: 99)
      end
    end
  end

  test "нельзя купить билет на черновик или прошедшее событие" do
    assert_raises(Order::NotOnSale) do
      Order.purchase!(user: users(:ivan), ticket_type: ticket_types(:workshop_standard))
    end
    assert_raises(Order::NotOnSale) do
      Order.purchase!(user: users(:ivan), ticket_type: ticket_types(:concert_standard))
    end
  end

  test "количество должно быть положительным" do
    assert_raises(ArgumentError) do
      Order.purchase!(user: users(:ivan), ticket_type: ticket_types(:conf_standard), quantity: 0)
    end
  end

  test "cancel! возвращает места и отменяет заказ" do
    order = orders(:ivan_conf)
    type = ticket_types(:conf_standard)

    order.cancel!

    assert order.reload.cancelled?
    assert_equal 0, type.reload.sold_count
  end

  test "повторная отмена ничего не меняет" do
    order = orders(:ivan_conf)
    order.cancel!
    order.cancel!
    assert_equal 0, ticket_types(:conf_standard).reload.sold_count
  end

  test "статус только из списка" do
    order = Order.new(user: users(:ivan), status: "refunded")
    assert_not order.valid?
    assert order.errors.of_kind?(:status, :inclusion)
  end

  test "сумма не может быть отрицательной" do
    assert_not Order.new(user: users(:ivan), total: -100).valid?
  end
end
