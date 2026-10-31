require "test_helper"

class FavoritesFlowTest < ActionDispatch::IntegrationTest
  JSON_HEADERS = { "Accept" => "application/json" }.freeze

  test "пользователь добавляет событие в избранное, видит его и убирает" do
    sign_in_via_form(users(:boris).email)
    event = events(:rails_conf)
    key = Favorite.key_for(event)

    get favorites_path
    assert_select "h2", text: "В избранном пока пусто"

    post favorite_path(key), headers: JSON_HEADERS
    assert_response :no_content

    get root_path
    assert_select "#event_#{event.id} .favorite-btn[aria-pressed=true]"

    get favorites_path
    assert_select "h3 a[href=?]", event_path(event)

    delete favorite_path(key), headers: JSON_HEADERS
    assert_response :no_content

    get favorites_path
    assert_select "h2", text: "В избранном пока пусто"
  end

  test "повторное добавление не создаёт дубль, а несуществующее событие отклоняется" do
    sign_in_via_form(users(:boris).email)
    key = Favorite.key_for(events(:ruby_meetup))

    assert_difference -> { users(:boris).favorites.count }, 1 do
      2.times { post favorite_path(key), headers: JSON_HEADERS }
    end

    post favorite_path("event-0"), headers: JSON_HEADERS
    assert_response :unprocessable_content
  end

  test "избранное демо-событие переезжает на настоящее после первой покупки" do
    demo = DemoEvent.all.find { |event| !event.sold_out? && !event.past? }

    sign_in_via_form(users(:boris).email)
    post favorite_path(Favorite.key_for(demo)), headers: JSON_HEADERS
    get favorites_path
    assert_select "h3 a[href=?]", demo_event_path(demo)
    delete destroy_user_session_path

    sign_in_via_form(users(:ivan).email)
    post demo_event_orders_path(demo), params: { order: { ticket_type_id: demo.ticket_types.first.id, quantity: 1 } }
    assert_redirected_to my_tickets_path
    delete destroy_user_session_path

    sign_in_via_form(users(:boris).email)
    get favorites_path
    assert_select "h3 a[href=?]", event_path(demo.imported_event)
  end

  test "гость не может добавить в избранное" do
    post favorite_path(Favorite.key_for(events(:rails_conf))), headers: JSON_HEADERS
    assert_response :unauthorized

    get favorites_path
    assert_redirected_to new_user_session_path
  end

  private

  def sign_in_via_form(email, password: "password123")
    post user_session_path, params: { user: { email: email, password: password } }
    assert_response :redirect
  end
end
