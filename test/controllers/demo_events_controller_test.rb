require "test_helper"

class DemoEventsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "страница демо-события открывается с описанием и билетами" do
    event = DemoEvent.find(1)

    get demo_event_path(event)

    assert_response :success
    assert_select "h1", event.title
    assert_match "О событии", response.body
    assert_match "Билеты", response.body
  end

  test "несуществующее демо-событие — 404" do
    get demo_event_path(id: 999)
    assert_response :not_found
  end

  test "карточки каталога ведут на страницы событий" do
    get root_path
    assert_select "a[href=?]", demo_event_path(DemoEvent.find(1))
  end

  test "посетитель покупает билет на демо-событие" do
    sign_in users(:ivan)
    demo = DemoEvent.find(3)
    stub = demo.ticket_types.first

    assert_difference -> { Event.count } => 1, -> { users(:ivan).tickets.count } => 2 do
      post demo_event_orders_path(demo), params: { order: { ticket_type_id: stub.id, quantity: 2 } }
    end

    assert_redirected_to my_tickets_path
    assert_equal stub.sold_count + 2, demo.imported_event.ticket_types.first.sold_count
  end

  test "после покупки страница демо-события ведёт на настоящее событие" do
    event = DemoEvent.find(3).import!

    get demo_event_path(DemoEvent.find(3))

    assert_redirected_to event_path(event)
  end

  test "организатор не может купить демо-событие, и оно не импортируется" do
    sign_in users(:anna)
    demo = DemoEvent.find(3)

    assert_no_difference -> { Event.count } do
      post demo_event_orders_path(demo), params: { order: { ticket_type_id: demo.ticket_types.first.id, quantity: 1 } }
    end
  end

  test "распроданное демо-событие купить нельзя" do
    sign_in users(:ivan)
    demo = DemoEvent.all.find(&:sold_out?)

    assert_no_difference -> { Order.count } do
      post demo_event_orders_path(demo), params: { order: { ticket_type_id: demo.ticket_types.first.id, quantity: 1 } }
    end
  end

  test "на странице демо-события посетитель видит форму покупки" do
    sign_in users(:ivan)
    demo = DemoEvent.find(3)

    get demo_event_path(demo)

    assert_select "form[action=?]", demo_event_orders_path(demo)
  end
end
