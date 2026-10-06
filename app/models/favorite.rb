class Favorite < ApplicationRecord
  KEY_FORMAT = /\A(event|demo_event)-(\d+)\z/

  belongs_to :user

  validates :event_key, format: { with: KEY_FORMAT }, uniqueness: { scope: :user_id }
  validate :event_must_exist

  def self.key_for(event)
    "#{event.model_name.param_key}-#{event.id}"
  end

  def self.find_event(key)
    type, id = key.to_s.match(KEY_FORMAT)&.captures
    case type
    when "event"      then Event.published.includes(:ticket_types, :organizer).find_by(id: id)
    when "demo_event" then DemoEvent.all.find { |demo| demo.id == id.to_i }&.then { |demo| demo.imported_event || demo }
    end
  end

  def self.resolve(keys)
    keys.filter_map { |key| find_event(key) }.uniq { |event| key_for(event) }
  end

  def self.move(from:, to:)
    taken = where(event_key: to).select(:user_id)
    where(event_key: from).where.not(user_id: taken).update_all(event_key: to)
    where(event_key: from).delete_all
  end

  def event
    self.class.find_event(event_key)
  end

  private

  def event_must_exist
    return unless event_key.to_s.match?(KEY_FORMAT)

    errors.add(:event_key, :invalid) if event.nil?
  end
end
