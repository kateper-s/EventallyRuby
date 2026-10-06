class Event < ApplicationRecord
  CATEGORIES = {
    "conference" => "Конференция",
    "meetup"     => "Митап",
    "concert"    => "Концерт",
    "workshop"   => "Воркшоп",
    "exhibition" => "Выставка",
    "sport"      => "Спорт"
  }.freeze

  CATEGORY_ICONS = {
    "conference" => :mic,
    "meetup"     => :coffee,
    "concert"    => :music,
    "workshop"   => :wrench,
    "exhibition" => :image,
    "sport"      => :trophy
  }.freeze

  belongs_to :organizer, class_name: "User", inverse_of: :organized_events
  has_many :ticket_types, -> { order(:price) }, dependent: :destroy, inverse_of: :event
  has_many :tickets, through: :ticket_types

  accepts_nested_attributes_for :ticket_types,
                                reject_if: ->(attrs) { attrs[:price].blank? && attrs[:quota].blank? }

  validates :title, presence: true, length: { maximum: 120 }
  validates :category, inclusion: { in: CATEGORIES.keys }
  validates :starts_at, :venue, :city, presence: true
  validate :ends_after_start
  validate :organizer_has_organizer_role

  scope :published, -> { where(published: true) }
  scope :upcoming, -> { where(starts_at: Time.current.beginning_of_day..).order(:starts_at) }
  scope :in_category, ->(category) { category.present? ? where(category: category) : all }
  scope :with_free_tickets, -> { where(id: TicketType.where(price: 0).select(:event_id)) }

  scope :search, lambda { |query|
    next all if query.blank?

    pattern = "%#{sanitize_sql_like(query.strip)}%"
    where(arel_table[:title].matches(pattern))
      .or(where(arel_table[:venue].matches(pattern)))
      .or(where(arel_table[:city].matches(pattern)))
  }

  def category_name
    CATEGORIES.fetch(category, category)
  end

  def category_icon
    CATEGORY_ICONS.fetch(category, :sparkles)
  end

  def min_price
    ticket_types.map(&:price).min
  end

  def free?
    ticket_types.any? && min_price.zero?
  end

  def capacity
    ticket_types.sum(&:quota)
  end

  def seats_left
    ticket_types.sum(&:available)
  end

  def sold_out?
    ticket_types.any? && seats_left.zero?
  end

  def past?
    starts_at.present? && starts_at < Time.current
  end

  def on_sale?
    published? && !past? && !sold_out?
  end

  def organizer_name
    organizer&.name
  end

  def price
    min_price.to_i
  end

  def image_url
    nil
  end

  def sold_count
    ticket_types.sum(&:sold_count)
  end

  def almost_sold_out?
    ticket_types.any? && !sold_out? && seats_left <= [capacity / 10, 15].max
  end

  def related(limit = 3)
    Event.published.upcoming.includes(:ticket_types, :organizer)
         .where(category: category).where.not(id: id).limit(limit)
  end

  private

  def ends_after_start
    return if ends_at.blank? || starts_at.blank?

    errors.add(:ends_at, :after_start) if ends_at <= starts_at
  end

  def organizer_has_organizer_role
    return if organizer.nil? || organizer.organizer?

    errors.add(:organizer, :not_organizer)
  end
end
