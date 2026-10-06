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

  TicketTypeStub = Struct.new(:name, :price, :quota, :sold_count, keyword_init: true) do
    def available = quota.to_i - sold_count.to_i
    def sold_out? = available <= 0
    def free? = price.to_i.zero?
    def id = name
  end

  DESCRIPTIONS = [
    "Главная конференция о Ruby on Rails в этом году: два потока докладов, воркшопы и много времени на нетворкинг.\n\nВ программе — Rails 8, Hotwire в продакшене, производительность Active Record и опыт команд, которые растят монолит годами. Обед и кофе-брейки включены в билет.",
    "Практический воркшоп для тех, кто хочет делать живые интерфейсы без SPA.\n\nЗа вечер соберём каталог с фильтрами на Turbo Frames, напишем несколько Stimulus-контроллеров и разберём типичные ошибки. Нужен ноутбук с установленным Ruby 3.3 и Rails 7.",
    "Сорок второй митап петербургского Ruby-сообщества. Тема вечера — скорость.\n\nДва доклада: как искать узкие места с rack-mini-profiler и stackprof и как мы ускорили фоновую обработку в пять раз. После докладов — пицца и общение.",
    "Камерный джазовый концерт под открытым небом с видом на крыши Петербурга.\n\nКвартет исполнит стандарты и собственные композиции. В случае дождя концерт переносится в зал этажом ниже.",
    "Юбилейная выставка о цифровом искусстве: от первых генеративных работ до интерактивных инсталляций.\n\nБолее 60 работ российских и зарубежных художников, VR-зона и экскурсии каждый час.",
    "Утренний забег на 10 км вдоль набережной для любого уровня подготовки.\n\nСтарт в 8:00, на финише — вода, фрукты и памятные медали. Регистрация обязательна, количество участников ограничено.",
    "Конференция для продуктовых дизайнеров: исследования, дизайн-системы и работа с метриками.\n\nСпикеры из крупных продуктовых команд расскажут о реальных кейсах, а в перерывах можно получить разбор портфолио.",
    "Вечер для тех, кто никогда не работал с глиной.\n\nМастер покажет основы лепки и работы на гончарном круге, каждый сделает свою чашку или тарелку. Изделия обжигаются и будут готовы через две недели.",
    "Митап про современный CSS: контейнерные запросы, :has(), каскадные слои и нативная вложенность.\n\nРазберём, что уже можно использовать в продакшене и без чего теперь можно обойтись.",
    "Симфонический оркестр исполнит музыку из любимых фильмов: от классики Голливуда до современных саундтреков.\n\nПродолжительность — около двух часов с антрактом.",
    "Открытый любительский турнир по настольному теннису в одиночном разряде.\n\nИгры по олимпийской системе, ракетки можно взять на месте. Победители получат призы от партнёров.",
    "Фотовыставка о жизни на Крайнем Севере: города, люди и природа за полярным кругом.\n\nЭкспозиция дополнена аудиогидом с рассказами авторов снимков."
  ].freeze

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
  attribute :description, :string

  def persisted? = true
  def to_param = id.to_s

  def category_name = CATEGORIES.dig(category, :label) || category
  def category_icon = CATEGORIES.dig(category, :icon) || :sparkles

  def free? = price.to_i.zero?
  def sold_out? = seats_left.to_i <= 0
  def almost_sold_out? = !sold_out? && seats_left.to_i <= [capacity.to_i / 10, 15].max
  def popularity = capacity.to_i - seats_left.to_i
  def sold_count = popularity
  def organizer_name = organizer
  def ends_at = nil
  def published? = true
  def past? = starts_at.present? && starts_at < Time.current
  def on_sale? = !past? && !sold_out?
  def min_price = price

  def ticket_types
    [TicketTypeStub.new(name: free? ? "Вход" : "Стандарт", price: price.to_i,
                        quota: capacity.to_i, sold_count: capacity.to_i - seats_left.to_i)]
  end

  def imported_event
    Event.published.includes(:ticket_types, :organizer).find_by(title: title)
  end

  def import!
    Event.transaction do
      event = imported_event || Event.create!(
        organizer: demo_organizer, title: title, description: description, category: category,
        starts_at: starts_at, venue: venue, city: city, published: true
      )
      Favorite.move(from: Favorite.key_for(self), to: Favorite.key_for(event))
      if event.ticket_types.empty?
        stub = ticket_types.first
        event.ticket_types.create!(name: stub.name, price: stub.price, quota: stub.quota, sold_count: stub.sold_count)
      end
      event
    end
  end

  def related(limit = 3)
    self.class.all.select { |event| event.category == category && event.id != id }.first(limit)
  end

  private

  def demo_organizer
    User.organizer.find_by(name: organizer) || User.create!(
      name: organizer, role: :organizer,
      email: "demo-#{Digest::MD5.hexdigest(organizer)[0, 10]}@eventally.test",
      password: SecureRandom.hex(16)
    )
  end

  public

  class << self
    def all
      # Даты считаются от текущего дня, чтобы фильтры «Сегодня» и «Выходные»
      # всегда что-то показывали.
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
      ].each_with_index.map { |attrs, i| new(id: i + 1, description: DESCRIPTIONS[i], **attrs) }
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
