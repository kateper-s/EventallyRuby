class DemoEvent
  include ActiveModel::Model
  include ActiveModel::Attributes

  CATEGORIES = {
    "conference" => { name: "Конференции", label: "Конференция", icon: :mic },
    "meetup"     => { name: "Митапы",      label: "Митап",       icon: :coffee },
    "concert"    => { name: "Концерты",    label: "Концерт",     icon: :music },
    "workshop"   => { name: "Воркшопы",    label: "Воркшоп",     icon: :wrench },
    "exhibition" => { name: "Выставки",    label: "Выставка",    icon: :image },
    "sport"      => { name: "Спорт",       label: "Спорт",       icon: :trophy }
  }.freeze

  PERIODS = {
    "today"   => "Сегодня",
    "weekend" => "Выходные",
    "week"    => "Неделя",
    "month"   => "Месяц"
  }.freeze

  SORTS = {
    "date"       => "Сначала ближайшие",
    "price_asc"  => "Сначала дешёвые",
    "price_desc" => "Сначала дорогие",
    "popular"    => "Популярные"
  }.freeze

  attribute :id, :integer
  attribute :title, :string
  attribute :category, :string
  attribute :starts_at, :datetime
  attribute :venue, :string
  attribute :city, :string
  attribute :price, :integer, default: 0
  attribute :capacity, :integer
  attribute :seats_left, :integer
  attribute :organizer, :string
  attribute :image_url, :string
  attribute :featured, :boolean, default: false

  def persisted? = true
  def to_param = id.to_s

  def category_name = CATEGORIES.dig(category, :label) || category
  def category_icon = CATEGORIES.dig(category, :icon) || :sparkles

  def free? = price.to_i.zero?
  def sold_out? = seats_left.to_i <= 0
  def almost_sold_out? = !sold_out? && seats_left.to_i <= [capacity.to_i / 10, 15].max
  def popularity = capacity.to_i - seats_left.to_i

  class << self
    def all
      today = Time.zone.now.beginning_of_day
      saturday = today + ((6 - today.wday) % 7).days
      sunday   = today.sunday? ? today : saturday + 1.day

      [
        { title: "Rails Conf Russia 2026", category: "conference", starts_at: saturday + 10.hours,
          venue: "Технопарк «Сколково»", city: "Москва", price: 4900, capacity: 600, seats_left: 84,
          organizer: "Ruby Community", featured: true },
        { title: "Hotwire без боли: Turbo и Stimulus на практике", category: "workshop", starts_at: today + 19.hours,
          venue: "Коворкинг «Точка кипения»", city: "Москва", price: 1500, capacity: 30, seats_left: 3,
          organizer: "Анна Смирнова" },
        { title: "Ruby Meetup #42: перформанс и профилирование", category: "meetup", starts_at: today + 1.day + 19.hours,
          venue: "Офис Evil Martians", city: "Санкт-Петербург", price: 0, capacity: 120, seats_left: 46,
          organizer: "SPb Ruby" },
        { title: "Джазовый вечер на крыше", category: "concert", starts_at: saturday + 20.hours + 30.minutes,
          venue: "Крыша на Гороховой", city: "Санкт-Петербург", price: 2200, capacity: 150, seats_left: 0,
          organizer: "Roof Music" },
        { title: "Выставка «Цифровое искусство: 10 лет»", category: "exhibition", starts_at: sunday + 12.hours,
          venue: "ЦСИ «Винзавод»", city: "Москва", price: 600, capacity: 400, seats_left: 230,
          organizer: "Винзавод" },
        { title: "Утренний забег по набережной 10 км", category: "sport", starts_at: sunday + 8.hours,
          venue: "Парк Горького", city: "Москва", price: 0, capacity: 500, seats_left: 312,
          organizer: "Run Club" },
        { title: "Product Design Conf", category: "conference", starts_at: today + 9.days + 10.hours,
          venue: "Loft Hall", city: "Казань", price: 3500, capacity: 350, seats_left: 140,
          organizer: "Design Union" },
        { title: "Воркшоп по керамике для начинающих", category: "workshop", starts_at: today + 4.days + 18.hours + 30.minutes,
          venue: "Студия «Глина»", city: "Екатеринбург", price: 2800, capacity: 12, seats_left: 5,
          organizer: "Студия «Глина»" },
        { title: "Frontend Meetup: CSS в 2026 году", category: "meetup", starts_at: today + 12.days + 19.hours,
          venue: "Яндекс, Красная Роза", city: "Москва", price: 0, capacity: 200, seats_left: 18,
          organizer: "MoscowCSS" },
        { title: "Симфонический оркестр: хиты кино", category: "concert", starts_at: today + 18.days + 19.hours,
          venue: "Зал «Зарядье»", city: "Москва", price: 3200, capacity: 1500, seats_left: 410,
          organizer: "Зарядье" },
        { title: "Турнир по настольному теннису", category: "sport", starts_at: today + 6.days + 11.hours,
          venue: "Спорткомплекс «Олимп»", city: "Новосибирск", price: 500, capacity: 64, seats_left: 22,
          organizer: "Ping Pong Club" },
        { title: "Фотовыставка «Север»", category: "exhibition", starts_at: today + 25.days + 11.hours,
          venue: "Музей Москвы", city: "Москва", price: 450, capacity: 300, seats_left: 250,
          organizer: "Музей Москвы" }
      ].each_with_index.map { |attrs, i| new(id: i + 1, **attrs) }
    end

    def find(id)
      all.find { |event| event.id == id.to_i } or raise ActiveRecord::RecordNotFound
    end

    def featured
      all.find(&:featured)
    end

    def cities
      all.map(&:city).uniq
    end

    def category_counts
      all.group_by(&:category).transform_values(&:size)
    end

    def search(q: nil, category: nil, period: nil, free: false, sort: "date")
      events = all.select { |event| event.starts_at >= Time.zone.now.beginning_of_day }
      events = events.select { |event| matches?(event, q) } if q.present?
      events = events.select { |event| event.category == category } if category.present?
      events = events.select { |event| in_period?(event, period) } if period.present?
      events = events.select(&:free?) if free

      case sort
      when "price_asc"  then events.sort_by { |e| [e.price, e.starts_at] }
      when "price_desc" then events.sort_by { |e| [-e.price, e.starts_at] }
      when "popular"    then events.sort_by { |e| -e.popularity }
      else                   events.sort_by(&:starts_at)
      end
    end

    private

    def matches?(event, query)
      haystack = [event.title, event.venue, event.city, event.organizer, event.category_name].join(" ").downcase
      query.downcase.split.all? { |word| haystack.include?(word) }
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
