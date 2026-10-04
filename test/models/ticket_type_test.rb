require "test_helper"

class TicketTypeTest < ActiveSupport::TestCase
  def build_type(**attrs)
    TicketType.new({ event: events(:rails_conf), name: "Студенческий", price: 1000, quota: 20 }.merge(attrs))
  end

  test "валиден с корректными данными" do
    assert build_type.valid?
  end

  test "цена не отрицательная и целая" do
    assert_not build_type(price: -1).valid?
    assert_not build_type(price: 10.5).valid?
    assert build_type(price: 0).valid?
  end

  test "квота больше нуля" do
    assert_not build_type(quota: 0).valid?
    assert build_type(quota: 1).valid?
  end

  test "квоту нельзя опустить ниже проданного" do
    type = ticket_types(:conf_standard)
    type.quota = 1
    assert_not type.valid?
    assert type.errors.of_kind?(:quota, :below_sold)
  end

  test "название уникально в пределах события" do
    assert_not build_type(name: "VIP").valid?
    assert build_type(name: "VIP", event: events(:ruby_meetup)).valid?
  end

  test "available и sold_out?" do
    assert_equal 98, ticket_types(:conf_standard).available
    assert_not ticket_types(:conf_standard).sold_out?
    assert ticket_types(:conf_vip).sold_out?
  end

  test "free?" do
    assert ticket_types(:meetup_free).free?
    assert_not ticket_types(:conf_standard).free?
  end

  test "ограничения продублированы в базе (CHECK)" do
    assert_raises(ActiveRecord::StatementInvalid) do
      ticket_types(:conf_standard).update_column(:sold_count, 1000)
    end
  end
end
