require "test_helper"

class CommentTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  def stream(event)
    Turbo::StreamsChannel.stream_name_from(Comment.stream_for(event))
  end

  test "фикстуры валидны, комментарии события идут по времени" do
    assert comments(:ivan_question).valid?
    assert_equal [comments(:ivan_question), comments(:anna_answer)], events(:rails_conf).comments.to_a
  end

  test "текст обязателен, обрезается по краям и ограничен по длине" do
    comment = Comment.new(event: events(:ruby_meetup), user: users(:ivan), body: "   ")
    assert_not comment.valid?
    assert comment.errors.added?(:body, :blank)

    comment.body = "  Вопрос  "
    assert comment.valid?
    assert_equal "Вопрос", comment.body

    comment.body = "а" * (Comment::MAX_LENGTH + 1)
    assert_not comment.valid?
  end

  test "черновик комментирует только его организатор" do
    draft = events(:draft_workshop)

    assert_not Comment.new(event: draft, user: users(:ivan), body: "Когда?").valid?
    assert Comment.new(event: draft, user: users(:anna), body: "Заметка для себя").valid?
  end

  test "by_organizer? и removable_by?" do
    question = comments(:ivan_question)
    answer = comments(:anna_answer)

    assert answer.by_organizer?
    assert_not question.by_organizer?

    assert question.removable_by?(users(:ivan))
    assert question.removable_by?(users(:anna))
    assert_not question.removable_by?(users(:boris))
    assert_not answer.removable_by?(users(:ivan))
    assert_not question.removable_by?(nil)
  end

  test "новый комментарий рассылается всем: добавляется в список и меняет счётчик" do
    event = events(:ruby_meetup)

    streams = capture_turbo_stream_broadcasts(stream(event)) do
      Comment.create!(event: event, user: users(:ivan), body: "Где парковка?")
    end

    assert_equal %w[append update], streams.map { |s| s["action"] }
    assert_equal %w[comments comments_count], streams.map { |s| s["target"] }
    assert_match "Где парковка?", streams.first.to_html
  end

  test "удалённый комментарий убирается у всех" do
    comment = comments(:ivan_question)

    streams = capture_turbo_stream_broadcasts(stream(comment.event)) { comment.destroy! }

    assert_equal %w[remove update], streams.map { |s| s["action"] }
    assert_equal "comment_#{comment.id}", streams.first["target"]
  end

  test "в базе тоже стоит ограничение на длину текста" do
    comment = comments(:ivan_question)

    assert_raises(ActiveRecord::StatementInvalid) do
      comment.update_column(:body, "")
    end
  end
end
