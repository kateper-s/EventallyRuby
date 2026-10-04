require "test_helper"

class TicketTest < ActiveSupport::TestCase
  test "код генерируется при создании" do
    ticket = orders(:ivan_conf).tickets.create!(ticket_type: ticket_types(:conf_standard), price: 4900)
    assert_equal 24, ticket.code.length
  end

  test "код уникален" do
    duplicate = orders(:ivan_conf).tickets.build(ticket_type: ticket_types(:conf_standard), price: 4900,
                                                 code: tickets(:ivan_conf_1).code)
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save! }
  end

  test "билет знает своё событие" do
    assert_equal events(:rails_conf), tickets(:ivan_conf_1).event
  end

  test "организатор события отмечает гостя на входе" do
    ticket = tickets(:ivan_conf_1)
    ticket.check_in!(by: users(:anna))
    assert ticket.reload.checked_in?
  end

  test "по одному билету нельзя пройти дважды" do
    ticket = tickets(:ivan_conf_1)
    ticket.check_in!(by: users(:anna))
    error = assert_raises(Ticket::CheckInError) { ticket.check_in!(by: users(:anna)) }
    assert_match "уже использован", error.message
  end

  test "чекин может делать только организатор этого события" do
    assert_raises(Ticket::CheckInError) { tickets(:ivan_conf_1).check_in!(by: users(:boris)) }
    assert_raises(Ticket::CheckInError) { tickets(:ivan_conf_1).check_in!(by: users(:ivan)) }
    assert_raises(Ticket::CheckInError) { tickets(:ivan_conf_1).check_in!(by: nil) }
  end

  test "билет из отменённого заказа не проходит" do
    ticket = tickets(:ivan_meetup_cancelled)
    assert_raises(Ticket::CheckInError) { ticket.check_in!(by: users(:boris)) }
    assert_not ticket.reload.checked_in?
  end
end
