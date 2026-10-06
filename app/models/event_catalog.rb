class EventCatalog
  PERIODS = DemoEvent::PERIODS
  SORTS   = DemoEvent::SORTS

  class << self
    def all
      events = published_events
      titles = events.map(&:title).to_set
      demos  = DemoEvent.all.reject { |demo| titles.include?(demo.title) }
      (events + demos).select { |event| event.starts_at >= today_start }
    end

    def featured
      demo = DemoEvent.featured
      demo&.imported_event || demo
    end

    def search(q: nil, category: nil, period: nil, from: nil, to: nil, free: false, sort: "date")
      events = all
      events = events.select { |event| matches?(event, q) } if q.present?
      events = events.select { |event| event.category == category } if category.present?

      if from || to
        events = events.select { |event| in_range?(event, from, to) }
      elsif period.present?
        events = events.select { |event| in_period?(event, period) }
      end

      events = events.select(&:free?) if free
      sorted(events, sort)
    end

    def category_counts(events = all)
      events.group_by(&:category).transform_values(&:size)
    end

    def cities(events = all)
      events.map(&:city).uniq
    end

    private

    def published_events
      Event.published.where(starts_at: today_start..).includes(:ticket_types, :organizer).to_a
    end

    def today_start
      Time.current.beginning_of_day
    end

    def sorted(events, sort)
      case sort
      when "price_asc"  then events.sort_by { |e| [e.price, e.starts_at] }
      when "price_desc" then events.sort_by { |e| [-e.price, e.starts_at] }
      when "popular"    then events.sort_by { |e| [-e.sold_count, e.starts_at] }
      else                   events.sort_by(&:starts_at)
      end
    end

    def matches?(event, query)
      haystack = [event.title, event.venue, event.city, event.organizer_name, event.category_name].join(" ").downcase
      query.downcase.split.all? { |word| haystack.include?(word) }
    end

    def in_range?(event, from, to)
      date = event.starts_at.to_date
      (from.nil? || date >= from) && (to.nil? || date <= to)
    end

    def in_period?(event, period)
      date  = event.starts_at.to_date
      today = Date.current

      case period
      when "today"   then date == today
      when "weekend" then (date.saturday? || date.sunday?) && date <= today.end_of_week
      when "week"    then date <= today + 7.days
      when "month"   then date <= today + 1.month
      else true
      end
    end
  end
end
