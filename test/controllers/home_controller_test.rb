require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "организатор видит свои события на главной" do
    sign_in users(:anna)

    get root_path

    assert_response :success
    assert_select "#my-events"
    assert_match events(:rails_conf).title, response.body
  end

  test "у посетителя и гостя блока «Мои события» нет" do
    get root_path
    assert_select "#my-events", count: 0

    sign_in users(:ivan)
    get root_path
    assert_select "#my-events", count: 0
  end

  test "опубликованное событие организатора видно всем в каталоге" do
    get root_path

    assert_select "#catalog h3 a", text: events(:rails_conf).title
    assert_select "#catalog h3 a", text: events(:draft_workshop).title, count: 0
  end

  test "фильтр по датам оставляет события только из диапазона" do
    get root_path, params: { from: 9.days.from_now.to_date.iso8601, to: 11.days.from_now.to_date.iso8601 }

    assert_response :success
    assert_select "#catalog h3 a", text: events(:rails_conf).title
    assert_select "#catalog h3 a", text: events(:ruby_meetup).title, count: 0
  end

  test "некорректная дата в параметрах не ломает страницу" do
    get root_path, params: { from: "не-дата" }

    assert_response :success
  end

  test "ссылки из каталога открывают страницу целиком, а не внутри turbo-frame" do
    get root_path

    assert_select "turbo-frame#events[target=_top]"
  end
end
