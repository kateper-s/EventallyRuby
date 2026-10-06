require "test_helper"

class MyTicketsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "посетитель видит свои билеты с кодами и статусами" do
    sign_in users(:ivan)

    get my_tickets_path

    assert_response :success
    assert_select "h3 a", text: events(:rails_conf).title
    assert_select "code", text: tickets(:ivan_conf_1).code.upcase
    assert_select "##{ActionView::RecordIdentifier.dom_id(tickets(:ivan_meetup_cancelled))} .badge", text: "Отменён"
  end

  test "без билетов показывается пустое состояние" do
    sign_in users(:anna)

    get my_tickets_path

    assert_response :success
    assert_select "h2", text: "Билетов пока нет"
  end

  test "гостя отправляют на вход" do
    get my_tickets_path

    assert_redirected_to new_user_session_path
  end
end
