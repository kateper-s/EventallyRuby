require "test_helper"

class CatalogFlowTest < ActionDispatch::IntegrationTest
  test "черновик виден только автору: во вкладке «Черновики», но не в каталоге" do
    post user_session_path, params: { user: { email: users(:anna).email, password: "password123" } }

    post events_path, params: { event: {
      title: "Секретный воркшоп", category: "workshop", starts_at: 6.days.from_now.change(hour: 18),
      venue: "Лофт", city: "Москва", published: "0",
      ticket_types_attributes: { "0" => { name: "Участник", price: "0", quota: "10" } }
    } }
    draft = Event.find_by!(title: "Секретный воркшоп")
    assert_not draft.published?
    follow_redirect!
    assert_match "Черновик: событие видите только вы", response.body

    get my_events_path(tab: "drafts")
    assert_select "h3 a", text: draft.title
    get my_events_path(tab: "upcoming")
    assert_select "h3 a", text: draft.title, count: 0

    get root_path
    assert_select "#catalog h3 a", text: draft.title, count: 0

    delete destroy_user_session_path
    post user_session_path, params: { user: { email: users(:ivan).email, password: "password123" } }
    get event_path(draft)
    assert_redirected_to root_path
  end

  test "поиск, категория, бесплатные и диапазон дат фильтруют каталог" do
    conf   = events(:rails_conf)
    meetup = events(:ruby_meetup)

    get root_path, params: { q: "Rails" }
    assert_select "#catalog h3 a", text: conf.title
    assert_select "#catalog h3 a", text: meetup.title, count: 0

    get root_path, params: { category: "meetup" }
    assert_select "#catalog h3 a", text: meetup.title
    assert_select "#catalog h3 a", text: conf.title, count: 0

    get root_path, params: { free: "1" }
    assert_select "#catalog h3 a", text: meetup.title
    assert_select "#catalog h3 a", text: conf.title, count: 0

    get root_path, params: { from: 9.days.from_now.to_date.iso8601, to: 11.days.from_now.to_date.iso8601 }
    assert_select "#catalog h3 a", text: conf.title
    assert_select "#catalog h3 a", text: meetup.title, count: 0
  end

  test "прошедшие события не попадают в каталог, а мусор в фильтрах не ломает страницу" do
    get root_path, params: { category: "hack", period: "never", from: "не-дата", sort: "drop table" }

    assert_response :success
    assert_select "#catalog h3 a", text: events(:past_concert).title, count: 0
    assert_select "#catalog h3 a", text: events(:rails_conf).title
  end

  test "ничего не найдено — показывается пустое состояние" do
    get root_path, params: { q: "такого-события-точно-нет" }

    assert_response :success
    assert_select "h3", text: "Ничего не нашлось"
  end
end
