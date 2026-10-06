require "test_helper"

class EventTest < ActiveSupport::TestCase
  def build_event(**attrs)
    Event.new({ organizer: users(:anna), title: "Новое событие", category: "meetup",
                starts_at: 5.days.from_now, venue: "Площадка", city: "Казань" }.merge(attrs))
  end

  test "фикстура валидна" do
    assert events(:rails_conf).valid?
  end

  test "обязательные поля" do
    event = Event.new
    assert_not event.valid?
    %i[title starts_at venue city].each do |attribute|
      assert event.errors.of_kind?(attribute, :blank), "ожидалась ошибка для #{attribute}"
    end
    assert event.errors.of_kind?(:organizer, :blank)
  end

  test "категория только из списка" do
    assert_not build_event(category: "party").valid?
    Event::CATEGORIES.each_key { |category| assert build_event(category: category).valid? }
  end

  test "окончание позже начала" do
    start = 5.days.from_now
    event = build_event(starts_at: start, ends_at: start - 1.hour)
    assert_not event.valid?
    assert event.errors.of_kind?(:ends_at, :after_start)
    assert build_event(starts_at: start, ends_at: start + 2.hours).valid?
  end

  test "проводить событие может только организатор" do
    event = build_event(organizer: users(:ivan))
    assert_not event.valid?
    assert event.errors.of_kind?(:organizer, :not_organizer)
  end

  test "published показывает только опубликованные" do
    assert_includes Event.published, events(:rails_conf)
    assert_not_includes Event.published, events(:draft_workshop)
  end

  test "upcoming не показывает прошедшие и сортирует по дате" do
    upcoming = Event.upcoming.to_a
    assert_not_includes upcoming, events(:past_concert)
    assert_equal upcoming.sort_by(&:starts_at), upcoming
    assert_equal events(:ruby_meetup), upcoming.first
  end

  test "in_category фильтрует, пустая категория — все события" do
    assert_equal [events(:ruby_meetup)], Event.in_category("meetup").to_a
    assert_equal Event.count, Event.in_category(nil).count
  end

  test "search ищет по названию, площадке и городу" do
    assert_includes Event.search("Сколково"), events(:rails_conf)
    assert_includes Event.search("Санкт"), events(:ruby_meetup)
    assert_not_includes Event.search("Санкт"), events(:rails_conf)
    assert_equal Event.count, Event.search("").count
  end

  test "search не учитывает регистр" do
    assert_includes Event.search("RAILS conf"), events(:rails_conf)
    assert_includes Event.search("evil martians"), events(:ruby_meetup)
  end

  test "search экранирует спецсимволы LIKE" do
    assert_empty Event.search("%")
    assert_empty Event.search("_")
  end

  test "with_free_tickets находит события с бесплатными билетами" do
    assert_equal [events(:ruby_meetup)], Event.with_free_tickets.to_a
  end

  test "цены и места считаются по типам билетов" do
    event = events(:rails_conf)
    assert_equal 4900, event.min_price
    assert_equal 101, event.capacity
    assert_equal 98, event.seats_left
    assert_not event.free?
    assert_not event.sold_out?
    assert events(:ruby_meetup).free?
  end

  test "событие без типов билетов не бесплатное и не распроданное" do
    event = build_event
    assert_nil event.min_price
    assert_not event.free?
    assert_not event.sold_out?
  end

  test "on_sale? учитывает публикацию и дату" do
    assert events(:rails_conf).on_sale?
    assert_not events(:draft_workshop).on_sale?
    assert_not events(:past_concert).on_sale?
  end

  test "category_name переводит категорию" do
    assert_equal "Конференция", events(:rails_conf).category_name
  end

  test "нельзя удалить событие с проданными билетами" do
    assert_no_difference -> { Event.count } do
      assert_not events(:rails_conf).destroy
    end
  end

  test "событие без продаж удаляется вместе с типами билетов" do
    assert_difference -> { TicketType.count }, -1 do
      events(:draft_workshop).destroy!
    end
  end

  test "organizer_name, price и sold_count для карточки" do
    event = events(:rails_conf)
    assert_equal "Анна Смирнова", event.organizer_name
    assert_equal 4900, event.price
    assert_equal 3, event.sold_count
  end

  test "related — опубликованные события той же категории без самого события" do
    other = Event.create!(organizer: users(:anna), title: "Ещё конференция", category: "conference",
                          starts_at: 15.days.from_now, venue: "Зал", city: "Москва", published: true)
    related = events(:rails_conf).related

    assert_includes related, other
    assert_not_includes related, events(:rails_conf)
    assert related.all? { |event| event.category == "conference" && event.published? }
  end
end
