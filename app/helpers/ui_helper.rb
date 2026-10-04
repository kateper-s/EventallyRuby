module UiHelper
  ICONS = {
    search:        '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
    plus:          '<path d="M12 5v14M5 12h14"/>',
    x:             '<path d="M18 6 6 18M6 6l12 12"/>',
    menu:          '<path d="M4 6h16M4 12h16M4 18h16"/>',
    chevron_down:  '<path d="m6 9 6 6 6-6"/>',
    chevron_right: '<path d="m9 6 6 6-6 6"/>',
    arrow_right:   '<path d="M5 12h14M13 6l6 6-6 6"/>',
    calendar:      '<rect x="3" y="4.5" width="18" height="16.5" rx="2.5"/><path d="M16 2.5v4M8 2.5v4M3 10h18"/>',
    clock:         '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    map_pin:       '<path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/>',
    heart:         '<path d="M19.5 12.6 12 20l-7.5-7.4A4.9 4.9 0 0 1 12 6.1a4.9 4.9 0 0 1 7.5 6.5Z"/>',
    ticket:        '<path d="M3 9a3 3 0 0 0 0 6v3a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-3a3 3 0 0 1 0-6V6a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2Z"/><path d="M13 5v2M13 17v2M13 11v2"/>',
    users:         '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.9M16 3.1a4 4 0 0 1 0 7.8"/>',
    check:         '<path d="M20 6 9 17l-5-5"/>',
    check_circle:  '<circle cx="12" cy="12" r="9"/><path d="m8.5 12 2.5 2.5 4.5-5"/>',
    alert_circle:  '<circle cx="12" cy="12" r="9"/><path d="M12 8v4.5M12 16h.01"/>',
    info:          '<circle cx="12" cy="12" r="9"/><path d="M12 16v-4.5M12 8h.01"/>',
    log_out:       '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/>',
    user:          '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
    sparkles:      '<path d="M12 3l1.8 4.7L18.5 9.5l-4.7 1.8L12 16l-1.8-4.7L5.5 9.5l4.7-1.8Z"/><path d="M19 15l.8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8Z"/>',
    sliders:       '<path d="M4 6h10M18 6h2M4 12h4M12 12h8M4 18h12M20 18h0"/><circle cx="16" cy="6" r="2"/><circle cx="10" cy="12" r="2"/><circle cx="18" cy="18" r="2"/>',
    mic:           '<rect x="9" y="2" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v4"/>',
    coffee:        '<path d="M17 8h1a4 4 0 0 1 0 8h-1M3 8h14v9a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4Z"/><path d="M6 2v2M10 2v2M14 2v2"/>',
    music:         '<path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/>',
    wrench:        '<path d="M14.7 6.3a4 4 0 0 0 5 5L22 14l-8 8-2.3-2.3a4 4 0 0 0-5-5L2 10l8-8 2.3 2.3a4 4 0 0 0 2.4 2Z"/>',
    image:         '<rect x="3" y="3" width="18" height="18" rx="2.5"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.1-3.1a2 2 0 0 0-2.8 0L6 21"/>',
    trophy:        '<path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6M18 9h1.5a2.5 2.5 0 0 0 0-5H18M4 22h16M10 14.7V17c0 .6-.5 1-1 1.2C7.8 18.8 7 20.2 7 22M14 14.7V17c0 .6.5 1 1 1.2 1.2.6 2 2 2 3.8"/><path d="M18 2H6v7a6 6 0 0 0 12 0Z"/>',
    grid:          '<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/>'
  }.freeze

  def icon(name, css_class: "size-4", stroke_width: 2, **attrs)
    paths = ICONS.fetch(name.to_sym) { raise ArgumentError, "Unknown icon: #{name}" }
    tag.svg(paths.html_safe,
            xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 24 24", fill: "none",
            stroke: "currentColor", "stroke-width": stroke_width,
            "stroke-linecap": "round", "stroke-linejoin": "round",
            class: css_class, "aria-hidden": "true", **attrs)
  end

  def avatar(name, size: nil, css_class: nil)
    initials = name.to_s.split.map { |part| part[0] }.first(2).join.upcase.presence || "?"
    tag.span(initials, class: ["avatar", ("avatar-#{size}" if size), css_class].compact.join(" "), title: name)
  end

  def nav_link(name, path, icon_name: nil, css_class: nil)
    active = path != "#" && current_page?(path)
    link_to path, class: ["nav-link", ("is-active" if active), css_class].compact.join(" "),
                  "aria-current": (active ? "page" : nil) do
      safe_join([icon_name && icon(icon_name), name].compact)
    end
  end

  def flash_style(type)
    case type.to_s
    when "notice", "success" then ["alert-success", :check_circle]
    when "warning"           then ["alert-warning", :alert_circle]
    else                          ["alert-error",   :alert_circle]
    end
  end

  MONTHS_GEN   = %w[января февраля марта апреля мая июня июля августа сентября октября ноября декабря].freeze
  MONTHS_SHORT = %w[янв фев мар апр мая июн июл авг сен окт ноя дек].freeze
  WEEKDAYS     = %w[Вс Пн Вт Ср Чт Пт Сб].freeze

  def event_datetime(time)
    day = case time.to_date
          when Date.current          then "Сегодня"
          when Date.current.tomorrow then "Завтра"
          else "#{WEEKDAYS[time.wday]}, #{time.day} #{MONTHS_SHORT[time.month - 1]}"
          end
    "#{day} · #{time.strftime('%H:%M')}"
  end

  def long_date(date)
    "#{date.day} #{MONTHS_GEN[date.month - 1]}"
  end

  def event_price(price)
    return "Бесплатно" if price.to_i.zero?

    "от #{number_with_delimiter(price, delimiter: ' ')} ₽"
  end

  def ru_plural(count, one, few, many, with_count: true)
    mod10  = count % 10
    mod100 = count % 100
    word = if mod10 == 1 && mod100 != 11 then one
           elsif (2..4).cover?(mod10) && !(12..14).cover?(mod100) then few
           else many
           end
    with_count ? "#{number_with_delimiter(count, delimiter: ' ')} #{word}" : word
  end
end
