require "test_helper"

class LiveUpdatesTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  setup do
    @event = events(:ruby_meetup)
    @ticket_type = ticket_types(:meetup_free)
  end

  def stream(*streamables)
    Turbo::StreamsChannel.stream_name_from(streamables)
  end

  test "покупка обновляет остаток мест у всех, кто смотрит событие" do
    streams = capture_turbo_stream_broadcasts(stream(@event)) do
      Order.purchase!(user: users(:ivan), ticket_type: @ticket_type, quantity: 3)
    end

    assert_equal 1, streams.size
    assert_equal "replace", streams.first["action"]
    assert_equal "availability_ticket_type_#{@ticket_type.id}", streams.first["target"]
    assert_match "Осталось 47 мест", streams.first.to_html
  end

  test "покупка обновляет панель продаж организатора в отдельном потоке" do
    streams = capture_turbo_stream_broadcasts(stream(@event, :sales)) do
      Order.purchase!(user: users(:ivan), ticket_type: @ticket_type, quantity: 2)
    end

    assert_equal ["sales"], streams.map { |s| s["target"] }
    assert_match(/2\s*<span[^>]*>из 50/, streams.first.to_html)
  end

  test "отмена заказа возвращает места и тоже рассылается" do
    order = Order.purchase!(user: users(:ivan), ticket_type: @ticket_type, quantity: 1)

    assert_turbo_stream_broadcasts stream(@event), count: 1 do
      order.cancel!
    end
  end

  test "изменение без смены продаж ничего не рассылает" do
    assert_no_turbo_stream_broadcasts stream(@event) do
      @ticket_type.update!(name: "Входной билет")
    end
  end

  test "неудачная покупка ничего не рассылает" do
    vip = ticket_types(:conf_vip)

    assert_no_turbo_stream_broadcasts stream(vip.event) do
      assert_raises(Order::SoldOut) { Order.purchase!(user: users(:ivan), ticket_type: vip, quantity: 1) }
    end
  end
end
