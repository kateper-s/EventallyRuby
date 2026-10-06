require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @event = events(:ruby_meetup)
    @ticket_type = ticket_types(:meetup_free)
  end

  test "посетитель покупает билеты и попадает в «Мои билеты»" do
    sign_in users(:ivan)

    assert_difference -> { users(:ivan).tickets.count } => 2, -> { Order.count } => 1 do
      post event_orders_path(@event), params: { order: { ticket_type_id: @ticket_type.id, quantity: 2 } }
    end

    assert_redirected_to my_tickets_path
    assert_equal 2, @ticket_type.reload.sold_count
    follow_redirect!
    assert_select "h3 a", text: @event.title
  end

  test "организатор видит продажу на странице своего события" do
    sign_in users(:ivan)
    post event_orders_path(@event), params: { order: { ticket_type_id: @ticket_type.id, quantity: 1 } }
    sign_out :user

    sign_in users(:boris)
    get event_path(@event)
    assert_select "#sales p", text: /\A\s*1\s+из 50\s*\z/
  end

  test "гостя отправляют на вход" do
    assert_no_difference -> { Order.count } do
      post event_orders_path(@event), params: { order: { ticket_type_id: @ticket_type.id, quantity: 1 } }
    end

    assert_redirected_to new_user_session_path
  end

  test "организатор не может купить билет" do
    sign_in users(:anna)

    assert_no_difference -> { Order.count } do
      post event_orders_path(@event), params: { order: { ticket_type_id: @ticket_type.id, quantity: 1 } }
    end
  end

  test "нельзя купить больше, чем осталось мест" do
    sign_in users(:ivan)
    vip = ticket_types(:conf_vip)

    assert_no_difference -> { Order.count } do
      post event_orders_path(events(:rails_conf)), params: { order: { ticket_type_id: vip.id, quantity: 1 } }
    end

    assert_redirected_to event_path(events(:rails_conf))
    assert_match "Не хватает мест", flash[:alert]
  end

  test "нельзя купить билет на прошедшее событие" do
    sign_in users(:ivan)
    event = events(:past_concert)

    assert_no_difference -> { Order.count } do
      post event_orders_path(event), params: { order: { ticket_type_id: ticket_types(:concert_standard).id, quantity: 1 } }
    end

    assert_redirected_to event_path(event)
  end

  test "некорректное количество и чужой тип билета отклоняются" do
    sign_in users(:ivan)

    assert_no_difference -> { Order.count } do
      post event_orders_path(@event), params: { order: { ticket_type_id: @ticket_type.id, quantity: 0 } }
      post event_orders_path(@event), params: { order: { ticket_type_id: @ticket_type.id, quantity: 50 } }
      post event_orders_path(@event), params: { order: { ticket_type_id: ticket_types(:conf_standard).id, quantity: 1 } }
      post event_orders_path(@event)
    end
  end

  test "на странице события посетитель видит форму покупки, гость — кнопку входа" do
    get event_path(@event)
    assert_select "form[action=?]", event_orders_path(@event), count: 0
    assert_select "a[href=?]", new_user_session_path

    sign_in users(:ivan)
    get event_path(@event)
    assert_select "form[action=?]", event_orders_path(@event)
  end

  test "после входа гость возвращается на страницу события" do
    get event_path(@event)
    post user_session_path, params: { user: { email: users(:ivan).email, password: "password123" } }

    assert_redirected_to event_path(@event)
  end
end
