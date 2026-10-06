class HomeController < ApplicationController
  def index
    @filters    = filter_params
    @events     = EventCatalog.search(**@filters)
    @featured   = EventCatalog.featured
    @categories = DemoEvent::CATEGORIES
    catalog = EventCatalog.all
    @category_counts = EventCatalog.category_counts(catalog)
    @stats = { events: catalog.size, cities: EventCatalog.cities(catalog).size }
    load_my_events if user_signed_in? && current_user.organizer?
  end

  private

  def load_my_events
    upcoming = current_user.organized_events.where(starts_at: Time.current..)
    @my_events_count = upcoming.count
    @my_events = upcoming.includes(:ticket_types, :organizer).order(:starts_at).limit(3)
  end

  def filter_params
    from = parse_date(params[:from])
    from = Date.current if from && from < Date.current
    {
      q:        params[:q].to_s.strip.first(100),
      category: params[:category].presence_in(DemoEvent::CATEGORIES.keys),
      period:   params[:period].presence_in(EventCatalog::PERIODS.keys),
      from:     from,
      to:       parse_date(params[:to]),
      free:     params[:free] == "1",
      sort:     params[:sort].presence_in(EventCatalog::SORTS.keys) || "date"
    }
  end

  def parse_date(value)
    Date.iso8601(value.to_s) if value.present?
  rescue Date::Error
    nil
  end
end
