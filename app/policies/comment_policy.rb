class CommentPolicy < ApplicationPolicy
  def create?
    user.present? && (record.event.published? || record.event.organizer_id == user.id)
  end

  def destroy?
    record.removable_by?(user)
  end
end
