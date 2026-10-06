require "test_helper"

class FavoritesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "на странице избранного видны отмеченные события" do
    sign_in users(:ivan)

    get favorites_path

    assert_response :success
    assert_select "h3 a", text: events(:rails_conf).title
    assert_select "h3 a", text: DemoEvent.find(5).title
    assert_select ".favorite-btn[aria-pressed=true]", count: 2
  end

  test "добавление и удаление из избранного" do
    sign_in users(:boris)
    key = Favorite.key_for(events(:ruby_meetup))

    assert_difference -> { users(:boris).favorites.count }, 1 do
      post favorite_path(key), as: :json
      post favorite_path(key), as: :json
    end
    assert_response :no_content

    assert_difference -> { users(:boris).favorites.count }, -1 do
      delete favorite_path(key), as: :json
    end
  end

  test "несуществующее событие добавить нельзя" do
    sign_in users(:boris)

    post favorite_path("event-0"), as: :json

    assert_response :unprocessable_content
  end

  test "гость получает 401 на добавление и редирект со страницы избранного" do
    post favorite_path("demo_event-1"), as: :json
    assert_response :unauthorized

    get favorites_path
    assert_redirected_to new_user_session_path
  end

  test "отмеченное событие подсвечено сердечком в каталоге" do
    sign_in users(:ivan)

    get root_path

    assert_select "#event_#{events(:rails_conf).id} .favorite-btn[aria-pressed=true]"
  end
end
