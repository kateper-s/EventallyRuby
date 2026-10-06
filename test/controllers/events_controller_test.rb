require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "organizer creates an event and lands on its page" do
    sign_in users(:anna)

    get new_event_path
    assert_response :success

    assert_difference -> { Event.count } => 1, -> { TicketType.count } => 1 do
      post events_path, params: { event: {
        title: "Ruby Meetup 43", category: "meetup", description: "Доклады про Rails",
        starts_at: 5.days.from_now.change(hour: 19), venue: "Точка кипения", city: "Москва",
        published: "1",
        ticket_types_attributes: { "0" => { name: "Стандарт", price: "500", quota: "50" } }
      } }
    end

    event = Event.order(:created_at).last
    assert_equal users(:anna), event.organizer
    assert_redirected_to event_path(event)

    follow_redirect!
    assert_response :success
    assert_select "h1", "Ruby Meetup 43"
    assert_match "500 ₽", response.body
  end

  test "invalid event re-renders the form" do
    sign_in users(:anna)

    assert_no_difference -> { Event.count } do
      post events_path, params: { event: { title: "", category: "meetup" } }
    end
    assert_response :unprocessable_content
  end

  test "visitor cannot create events" do
    sign_in users(:ivan)

    get new_event_path
    assert_redirected_to root_path
  end

  test "guest is asked to sign in" do
    get new_event_path
    assert_redirected_to new_user_session_path
  end

  test "anyone sees a published event" do
    get event_path(events(:rails_conf))
    assert_response :success
    assert_select "h1", events(:rails_conf).title
  end

  test "draft is visible only to its organizer" do
    get event_path(events(:draft_workshop))
    assert_redirected_to root_path

    sign_in users(:anna)
    get event_path(events(:draft_workshop))
    assert_response :success
  end
end
