require "test_helper"

class BranchesTest < ActionDispatch::IntegrationTest
  test "посетитель не может создать событие" do
    sign_in_via_form(users(:ivan).email)

    get new_event_path
    assert_redirected_to root_path
    follow_redirect!
    assert_select ".alert", text: /У вас нет доступа к этой странице/

    assert_no_difference -> { Event.count } do
      post events_path, params: { event: {
        title: "Чужое событие", category: "meetup", starts_at: 3.days.from_now,
        venue: "Офис", city: "Москва", published: "1"
      } }
    end
    assert_redirected_to root_path
  end

  test "организатор не может купить билет, даже на чужое событие" do
    sign_in_via_form(users(:anna).email)
    event = events(:ruby_meetup)

    get event_path(event)
    assert_select "form[action=?]", event_orders_path(event), count: 0
    assert_match "Покупать билеты могут только посетители", response.body

    assert_no_difference -> { Order.count } do
      post event_orders_path(event), params: { order: { ticket_type_id: ticket_types(:meetup_free).id, quantity: 1 } }
    end
    assert_redirected_to root_path
    follow_redirect!
    assert_select ".alert", text: /У вас нет доступа к этой странице/
  end

  test "последний билет достаётся первому, второй покупатель получает ошибку" do
    event = users(:boris).organized_events.create!(
      title: "Камерный концерт", category: "concert", starts_at: 4.days.from_now,
      venue: "Лофт", city: "Москва", published: true,
      ticket_types_attributes: [{ name: "Место", price: 1000, quota: 1 }]
    )
    ticket_type = event.ticket_types.first
    second = User.create!(name: "Мария", email: "maria@example.com", role: :visitor,
                          password: "password123", password_confirmation: "password123")

    sign_in_via_form(users(:ivan).email)
    post event_orders_path(event), params: { order: { ticket_type_id: ticket_type.id, quantity: 1 } }
    assert_redirected_to my_tickets_path
    sign_out_via_form

    sign_in_via_form(second.email)
    get event_path(event)
    assert_select ".btn", text: "Билеты закончились"
    assert_select "form[action=?]", event_orders_path(event), count: 0

    assert_no_difference -> { Order.count } do
      post event_orders_path(event), params: { order: { ticket_type_id: ticket_type.id, quantity: 1 } }
    end
    assert_redirected_to event_path(event)
    follow_redirect!
    assert_select ".alert", text: /Не хватает мест: осталось 0/
    assert_equal 1, ticket_type.reload.sold_count
  end

  test "чужой черновик не виден и не продаётся" do
    draft = events(:draft_workshop)
    sign_in_via_form(users(:ivan).email)

    get event_path(draft)
    assert_redirected_to root_path

    assert_no_difference -> { Order.count } do
      post event_orders_path(draft), params: { order: { ticket_type_id: ticket_types(:workshop_standard).id, quantity: 1 } }
    end

    get root_path
    assert_select "#catalog h3 a", text: draft.title, count: 0
  end

  test "гость при покупке отправляется на вход, а неполная форма события не сохраняется" do
    event = events(:ruby_meetup)

    assert_no_difference -> { Order.count } do
      post event_orders_path(event), params: { order: { ticket_type_id: ticket_types(:meetup_free).id, quantity: 1 } }
    end
    assert_redirected_to new_user_session_path

    sign_in_via_form(users(:anna).email)
    assert_no_difference -> { Event.count } do
      post events_path, params: { event: { title: "", category: "meetup", venue: "", city: "" } }
    end
    assert_response :unprocessable_content
    assert_select "#error_explanation li", minimum: 3
  end

  private

  def sign_in_via_form(email, password: "password123")
    post user_session_path, params: { user: { email: email, password: password } }
    assert_response :redirect
  end

  def sign_out_via_form
    delete destroy_user_session_path
    assert_response :redirect
  end
end
