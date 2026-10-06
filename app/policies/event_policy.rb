class EventPolicy < ApplicationPolicy
  def show?
    record.published? || owner?
  end

  def create?
    user&.organizer?
  end

  def manage?
    user&.organizer?
  end

  def buy?
    user.present? && user.visitor? && record.published?
  end

  private

  def owner?
    user.present? && record.organizer_id == user.id
  end
end
