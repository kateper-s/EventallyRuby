require "test_helper"

class MyEventsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "организатор видит только свои предстоящие события" do
    sign_in users(:anna)

    get my_events_path

    assert_response :success
    assert_match events(:rails_conf).title, response.body
    assert_no_match events(:ruby_meetup).title, response.body
    assert_no_match events(:draft_workshop).title, response.body
  end

  test "черновики на отдельной вкладке" do
    sign_in users(:anna)

    get my_events_path(tab: "drafts")

    assert_match events(:draft_workshop).title, response.body
    assert_no_match events(:rails_conf).title, response.body
  end

  test "прошедшие на отдельной вкладке" do
    sign_in users(:anna)

    get my_events_path(tab: "past")

    assert_match events(:past_concert).title, response.body
  end

  test "посетителю страница недоступна" do
    sign_in users(:ivan)

    get my_events_path

    assert_redirected_to root_path
  end

  test "гостя просят войти" do
    get my_events_path
    assert_redirected_to new_user_session_path
  end
end
