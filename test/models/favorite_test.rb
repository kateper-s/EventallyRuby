require "test_helper"

class FavoriteTest < ActiveSupport::TestCase
  test "ключ строится из типа и id события" do
    assert_equal "event-#{events(:rails_conf).id}", Favorite.key_for(events(:rails_conf))
    assert_equal "demo_event-3", Favorite.key_for(DemoEvent.find(3))
  end

  test "можно добавить настоящее и демо-событие" do
    user = users(:boris)

    assert user.favorites.create(event_key: Favorite.key_for(events(:ruby_meetup))).persisted?
    assert user.favorites.create(event_key: "demo_event-1").persisted?
  end

  test "ключ неверного формата или несуществующего события не сохраняется" do
    user = users(:boris)

    %w[hack event-abc demo_event-999 event-0].each do |key|
      assert_not user.favorites.build(event_key: key).valid?, key
    end
    assert_not user.favorites.build(event_key: Favorite.key_for(events(:draft_workshop))).valid?
  end

  test "одно событие нельзя добавить в избранное дважды" do
    duplicate = users(:ivan).favorites.build(event_key: favorites(:ivan_conf).event_key)

    assert_not duplicate.valid?
  end

  test "resolve превращает ключи в события и пропускает пропавшие" do
    events = Favorite.resolve(["event-#{events(:rails_conf).id}", "demo_event-5", "event-0"])

    assert_equal [events(:rails_conf).title, DemoEvent.find(5).title], events.map(&:title)
  end

  test "при импорте демо-события избранное переезжает на настоящее событие" do
    event = DemoEvent.find(5).import!

    assert_equal Favorite.key_for(event), favorites(:ivan_demo).reload.event_key
    assert_equal [event], Favorite.resolve([favorites(:ivan_demo).event_key])
  end
end
