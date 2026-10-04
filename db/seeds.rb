PASSWORD = "password123"

def seed_user(name:, email:, role:)
  User.find_or_create_by!(email: email) do |user|
    user.name = name
    user.role = role
    user.password = PASSWORD
    user.password_confirmation = PASSWORD
  end
end

anna   = seed_user(name: "Анна Смирнова",  email: "anna@eventally.test",  role: :organizer)
ruby   = seed_user(name: "Ruby Community", email: "ruby@eventally.test",  role: :organizer)
ivan   = seed_user(name: "Иван Петров",    email: "ivan@eventally.test",  role: :visitor)
_maria = seed_user(name: "Мария Козлова",  email: "maria@eventally.test", role: :visitor)

today = Time.zone.now.beginning_of_day

events = [
  { organizer: ruby, title: "Rails Conf Russia 2026", category: "conference",
    starts_at: today + 10.days + 10.hours, ends_at: today + 10.days + 19.hours,
    venue: "Технопарк «Сколково»", city: "Москва",
    description: "Главная конференция о Ruby on Rails: доклады, воркшопы и нетворкинг.",
    ticket_types: [["Стандарт", 4900, 500], ["VIP", 12_000, 50]] },
  { organizer: anna, title: "Hotwire без боли: Turbo и Stimulus", category: "workshop",
    starts_at: today + 2.days + 19.hours, venue: "Коворкинг «Точка кипения»", city: "Москва",
    description: "Практический воркшоп: пишем интерактивный интерфейс без SPA.",
    ticket_types: [["Участник", 1500, 30]] },
  { organizer: ruby, title: "Ruby Meetup #42", category: "meetup",
    starts_at: today + 4.days + 19.hours, venue: "Офис Evil Martians", city: "Санкт-Петербург",
    ticket_types: [["Вход", 0, 120]] },
  { organizer: anna, title: "Джазовый вечер на крыше", category: "concert",
    starts_at: today + 6.days + 20.hours, venue: "Крыша на Гороховой", city: "Санкт-Петербург",
    ticket_types: [["Танцпол", 2200, 100], ["Столик на двоих", 6000, 10]] },
  { organizer: anna, title: "Выставка «Цифровое искусство»", category: "exhibition",
    starts_at: today + 7.days + 12.hours, venue: "ЦСИ «Винзавод»", city: "Москва",
    ticket_types: [["Входной", 600, 400]] },
  { organizer: ruby, title: "Утренний забег 10 км", category: "sport",
    starts_at: today + 8.days + 8.hours, venue: "Парк Горького", city: "Москва",
    ticket_types: [["Участник", 0, 500]] },
  { organizer: anna, title: "Product Design Conf", category: "conference",
    starts_at: today + 15.days + 10.hours, venue: "Loft Hall", city: "Казань",
    ticket_types: [["Стандарт", 3500, 350]] },
  { organizer: anna, title: "Черновик: воркшоп по керамике", category: "workshop", published: false,
    starts_at: today + 20.days + 18.hours, venue: "Студия «Глина»", city: "Екатеринбург",
    ticket_types: [["Участник", 2800, 12]] }
].freeze

events.each do |data|
  attrs = data.except(:ticket_types).reverse_merge(published: true)
  event = Event.find_or_create_by!(title: attrs[:title]) { |e| e.assign_attributes(attrs) }

  data[:ticket_types].each do |name, price, quota|
    event.ticket_types.find_or_create_by!(name: name) do |type|
      type.price = price
      type.quota = quota
    end
  end
end

if ivan.orders.none?
  conf = Event.find_by!(title: "Rails Conf Russia 2026")
  Order.purchase!(user: ivan, ticket_type: conf.ticket_types.find_by!(name: "Стандарт"), quantity: 2)
  Order.purchase!(user: ivan, ticket_type: Event.find_by!(title: "Ruby Meetup #42").ticket_types.first)
end

puts "Пользователей: #{User.count}, событий: #{Event.count}, типов билетов: #{TicketType.count}, билетов: #{Ticket.count}"
puts "Вход: anna@eventally.test (организатор) или ivan@eventally.test (посетитель), пароль #{PASSWORD}"
