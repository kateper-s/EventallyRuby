require "test_helper"

class LivePageTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper

  TURBO = { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }.freeze

  def stream(*streamables)
    Turbo::StreamsChannel.stream_name_from(streamables)
  end

  test "страница события подписывается на нужные потоки: гость на два, владелец на три" do
    event = events(:rails_conf)

    get event_path(event)
    assert_select "turbo-cable-stream-source", count: 2
    assert_select "turbo-cable-stream-source[signed-stream-name=?]", Turbo::StreamsChannel.signed_stream_name([event, :sales]), count: 0

    sign_in_via_form(users(:anna).email)
    get event_path(event)
    assert_select "turbo-cable-stream-source", count: 3
    assert_select "#sales .live-dot"
  end

  test "посетитель задаёт вопрос: ответ приходит турбо-стримом, остальным — через Action Cable" do
    event = events(:ruby_meetup)
    sign_in_via_form(users(:ivan).email)

    get event_path(event)
    assert_select "#comments_count", text: "0"
    assert_select "form#comment_form[action=?]", event_comments_path(event)

    broadcasts = capture_turbo_stream_broadcasts(stream(event, :comments)) do
      assert_difference -> { event.comments.count }, 1 do
        post event_comments_path(event), params: { comment: { body: "Можно прийти с ребёнком?" } }, headers: TURBO
      end
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "turbo-stream[action=append][target=comments]"
    assert_select "turbo-stream[action=replace][target=comment_form]"
    assert_equal %w[append update], broadcasts.map { |s| s["action"] }

    get event_path(event)
    assert_select "#comments .comment", text: /Можно прийти с ребёнком\?/
    assert_select "#comments_count", text: "1"
  end

  test "организатор отвечает с пометкой «Организатор» и может удалить чужой вопрос" do
    event = events(:rails_conf)
    question = comments(:ivan_question)
    sign_in_via_form(users(:anna).email)

    post event_comments_path(event), params: { comment: { body: "Запись будет на YouTube" } }, headers: TURBO
    assert_select "turbo-stream[action=append][target=comments]"
    assert_match(/badge[^>]*>\s*Организатор/, response.body)

    assert_turbo_stream_broadcasts stream(event, :comments), count: 2 do
      delete event_comment_path(event, question), headers: TURBO
    end
    assert_select "turbo-stream[action=remove][target=?]", "comment_#{question.id}"
    assert_not Comment.exists?(question.id)
  end

  test "пустой вопрос не сохраняется, форма возвращается с ошибкой" do
    event = events(:ruby_meetup)
    sign_in_via_form(users(:ivan).email)

    assert_no_difference -> { Comment.count } do
      post event_comments_path(event), params: { comment: { body: "   " } }, headers: TURBO
    end
    assert_response :unprocessable_content
    assert_select "turbo-stream[action=replace][target=comment_form]"
    assert_match "field-error-text", response.body
  end

  test "посетитель не может удалить чужой комментарий, гость не может писать, черновик закрыт" do
    event = events(:rails_conf)

    post event_comments_path(event), params: { comment: { body: "Привет" } }
    assert_redirected_to new_user_session_path

    sign_in_via_form(users(:ivan).email)
    delete event_comment_path(event, comments(:anna_answer))
    assert_redirected_to root_path
    assert Comment.exists?(comments(:anna_answer).id)

    draft = events(:draft_workshop)
    assert_no_difference -> { Comment.count } do
      post event_comments_path(draft), params: { comment: { body: "Когда откроют?" } }
    end
    assert_redirected_to root_path
  end

  test "покупка билета сразу меняет остаток мест у всех зрителей события" do
    event = events(:ruby_meetup)
    ticket_type = ticket_types(:meetup_free)
    sign_in_via_form(users(:ivan).email)

    get event_path(event)
    assert_select "#availability_ticket_type_#{ticket_type.id}", text: /Осталось 50 мест/

    broadcasts = capture_turbo_stream_broadcasts(stream(event)) do
      post event_orders_path(event), params: { order: { ticket_type_id: ticket_type.id, quantity: 2 } }
    end
    assert_redirected_to my_tickets_path

    assert_equal ["availability_ticket_type_#{ticket_type.id}"], broadcasts.map { |s| s["target"] }
    assert_match "Осталось 48 мест", broadcasts.first.to_html
  end

  private

  def sign_in_via_form(email, password: "password123")
    post user_session_path, params: { user: { email: email, password: password } }
    assert_response :redirect
  end
end
