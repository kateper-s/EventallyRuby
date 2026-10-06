require "test_helper"

class DemoEventTest < ActiveSupport::TestCase
  test "у каждого демо-события есть описание" do
    assert DemoEvent.all.all? { |event| event.description.present? }
  end

  test "find находит событие по id, а для несуществующего кидает RecordNotFound" do
    assert_equal 1, DemoEvent.find(1).id
    assert_raises(ActiveRecord::RecordNotFound) { DemoEvent.find(999) }
  end

  test "тип билета собирается из цены и мест" do
    event = DemoEvent.find(1)
    ticket_type = event.ticket_types.first

    assert_equal event.price, ticket_type.price
    assert_equal event.seats_left, ticket_type.available
  end

  test "похожие события той же категории и без самого события" do
    event = DemoEvent.find(1)
    related = event.related

    assert related.all? { |other| other.category == event.category }
    assert_not_includes related.map(&:id), event.id
  end

  test "import! создаёт настоящее событие с типом билета и проданными местами" do
    demo = DemoEvent.find(3)

    event = assert_difference -> { Event.count } => 1 do
      demo.import!
    end

    assert event.published?
    assert_equal demo.title, event.title
    assert_equal demo.capacity - demo.seats_left, event.ticket_types.first.sold_count
    assert_equal demo.seats_left, event.seats_left
    assert event.organizer.organizer?
  end

  test "import! повторно не создаёт дубликат" do
    demo = DemoEvent.find(3)
    first = demo.import!

    assert_no_difference -> { Event.count } do
      assert_equal first, demo.import!
    end
  end

  test "import! использует существующего организатора с тем же именем" do
    demo = DemoEvent.all.find { |event| event.organizer == users(:anna).name }

    assert_equal users(:anna), demo.import!.organizer
  end
end
