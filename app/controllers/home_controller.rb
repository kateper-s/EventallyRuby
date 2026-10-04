class HomeController < ApplicationController
  def index
    @filters    = filter_params
    @events     = DemoEvent.search(**@filters)
    @featured   = DemoEvent.featured
    @categories = DemoEvent::CATEGORIES
    @category_counts = DemoEvent.category_counts
    @stats = { events: DemoEvent.all.size, cities: DemoEvent.cities.size }
  end

  private

  def filter_params
    {
      q:        params[:q].to_s.strip.first(100),
      category: params[:category].presence_in(DemoEvent::CATEGORIES.keys),
      period:   params[:period].presence_in(DemoEvent::PERIODS.keys),
      free:     params[:free] == "1",
      sort:     params[:sort].presence_in(DemoEvent::SORTS.keys) || "date"
    }
  end
end
