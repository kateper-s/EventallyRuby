require "test_helper"

class HappyPathTest < ActionDispatch::IntegrationTest
  test "организатор создаёт событие, посетитель покупает билет, организатор видит продажу" do
    register(name: "Ольга Организатор", email: "olga@example.com", role: "organizer")
    assert_redirected_to root_path

    get new_event_path
    assert_response :success
    assert_select "form[action=?]", events_path

    assert_difference -> { Event.count } => 1, -> { TicketType.count } => 1 do
      post events_path, params: { event: {
        title: "Rails-воркшоп для начинающих", category: "workshop",
        description: "Соберём первое приложение на Rails",
        starts_at: 7.days.from_now.change(hour: 18), venue: "Точка кипения", city: "Казань",
        published: "1",
        ticket_types_attributes: { "0" => { name: "Участник", price: "700", quota: "30" } }
      } }
    end
    event = Event.find_by!(title: "Rails-воркшоп для начинающих")
    assert_redirected_to event_path(event)
    follow_redirect!
    assert_select "h1", event.title
    assert_select "#sales p", text: /\A\s*0\s+из 30\s*\z/

    sign_out_via_form

    get root_path
    assert_select "#catalog h3 a[href=?]", event_path(event), text: event.title

    get event_path(event)
    assert_select "a[href=?]", new_user_session_path, text: /Войти и купить билет/
    assert_select "form[action=?]", event_orders_path(event), count: 0

    register(name: "Пётр Посетитель", email: "petr@example.com", role: "visitor")
    assert_redirected_to event_path(event)
    follow_redirect!
    assert_select "form[action=?]", event_orders_path(event)

    ticket_type = event.ticket_types.first
    assert_difference -> { Order.count } => 1, -> { Ticket.count } => 2 do
      post event_orders_path(event), params: { order: { ticket_type_id: ticket_type.id, quantity: 2 } }
    end
    assert_redirected_to my_tickets_path
    follow_redirect!
    assert_match "Готово!", response.body
    assert_select "h3 a", text: event.title
    assert_select "code.ticket-code", count: 2
    assert_select ".badge", text: /Действителен/, count: 2

    order = User.find_by!(email: "petr@example.com").orders.last
    assert order.paid?
    assert_equal 1400, order.total
    assert_equal 2, ticket_type.reload.sold_count

    sign_out_via_form
    sign_in_via_form("olga@example.com", password: "secret123")

    get my_events_path
    assert_response :success
    assert_select "#event_#{event.id}", text: /Продано\s+2\s+из 30/

    get event_path(event)
    assert_select "#sales p", text: /\A\s*2\s+из 30\s*\z/
  end

  test "посетитель покупает билет на демо-событие, и оно становится настоящим" do
    demo = DemoEvent.all.find { |event| !event.sold_out? && !event.past? }
    sign_in_via_form(users(:ivan).email)

    get demo_event_path(demo)
    assert_select "form[action=?]", demo_event_orders_path(demo)

    assert_difference -> { Event.count } => 1, -> { users(:ivan).tickets.count } => 1 do
      post demo_event_orders_path(demo), params: { order: { ticket_type_id: demo.ticket_types.first.id, quantity: 1 } }
    end
    assert_redirected_to my_tickets_path
    follow_redirect!
    assert_select "h3 a", text: demo.title

    event = demo.imported_event
    get demo_event_path(demo)
    assert_redirected_to event_path(event)
  end

  private

  def register(name:, email:, role:)
    get new_user_registration_path
    assert_response :success
    post user_registration_path, params: { user: {
      name: name, email: email, role: role, password: "secret123", password_confirmation: "secret123"
    } }
  end

  def sign_in_via_form(email, password: "password123")
    post user_session_path, params: { user: { email: email, password: password } }
    assert_response :redirect
  end

  def sign_out_via_form
    delete destroy_user_session_path
    assert_response :redirect
  end
end
