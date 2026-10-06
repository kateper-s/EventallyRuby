require "test_helper"

class EventCatalogTest < ActiveSupport::TestCase
  test "в каталоге есть опубликованные события из базы и демо-события" do
    titles = EventCatalog.all.map(&:title)

    assert_includes titles, events(:rails_conf).title
    assert_includes titles, events(:ruby_meetup).title
    assert_includes titles, DemoEvent.find(1).title
  end

  test "черновики и прошедшие события в каталог не попадают" do
    titles = EventCatalog.all.map(&:title)

    assert_not_includes titles, events(:draft_workshop).title
    assert_not_includes titles, events(:past_concert).title
  end

  test "только что опубликованное событие сразу появляется в каталоге" do
    event = users(:anna).organized_events.create!(
      title: "Новое событие Анны", category: "meetup", starts_at: 2.days.from_now,
      venue: "Офис", city: "Москва", published: true
    )

    assert_includes EventCatalog.all, event
  end

  test "фильтр по диапазону дат" do
    from = 9.days.from_now.to_date
    to   = 11.days.from_now.to_date
    events = EventCatalog.search(from: from, to: to)

    assert_includes events, events(:rails_conf)
    assert_not_includes events, events(:ruby_meetup)
    assert events.all? { |event| event.starts_at.to_date.between?(from, to) }
  end

  test "диапазон дат важнее быстрого периода" do
    events = EventCatalog.search(period: "today", from: 9.days.from_now.to_date)

    assert_includes events, events(:rails_conf)
  end

  test "поиск, категория и сортировка работают для обоих видов событий" do
    events = EventCatalog.search(q: "rails", category: "conference")

    assert_includes events, events(:rails_conf)
    assert events.all? { |event| event.category == "conference" }
    assert_equal events.sort_by(&:starts_at), events
  end

  test "счётчики категорий считают и настоящие события" do
    demo_meetups = DemoEvent.all.count { |event| event.category == "meetup" && event.starts_at >= Time.current.beginning_of_day }

    assert_equal demo_meetups + 1, EventCatalog.category_counts["meetup"]
  end

  test "после импорта демо-событие не дублируется в каталоге" do
    demo = DemoEvent.find(3)
    event = demo.import!
    same_title = EventCatalog.all.select { |item| item.title == demo.title }

    assert_equal [event], same_title
    assert_equal event, EventCatalog.featured if demo.featured
  end
end
