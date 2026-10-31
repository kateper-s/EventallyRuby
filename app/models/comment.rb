class Comment < ApplicationRecord
  MAX_LENGTH = 1000

  belongs_to :event
  belongs_to :user

  before_validation { self.body = body.to_s.strip }

  validates :body, presence: true, length: { maximum: MAX_LENGTH }
  validate :event_open_for_comments

  after_create_commit :broadcast_created
  after_destroy_commit :broadcast_removed

  def by_organizer?
    user_id == event.organizer_id
  end

  def removable_by?(someone)
    someone.present? && (someone.id == user_id || someone.id == event.organizer_id)
  end

  def self.stream_for(event)
    [event, :comments]
  end

  private

  def event_open_for_comments
    return if event.nil? || event.published? || user_id == event.organizer_id

    errors.add(:event, :not_published)
  end

  def broadcast_created
    broadcast_append_to(*Comment.stream_for(event), target: "comments",
                        partial: "comments/comment", locals: { comment: self })
    broadcast_count
  end

  def broadcast_removed
    broadcast_remove_to(*Comment.stream_for(event))
    broadcast_count
  end

  def broadcast_count
    broadcast_update_to(*Comment.stream_for(event), target: "comments_count",
                        partial: "comments/count", locals: { count: event.comments.count })
  end
end
