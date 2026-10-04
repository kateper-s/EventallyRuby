# EventallyRuby
Веб-платформа для организации мероприятий : от создания события и продажи билетов до чекина гостей.


## Возможности

**Организаторам:**
- Создание событий с обложкой, описанием, местом на карте
- Несколько типов билетов с квотами

**Посетителям:**
- Каталог с поиском и фильтрами
- Покупка билетов
- Личный кабинет

## Запуск

```bash
bin/setup            # гемы + база + миграции
bin/rails db:seed    # демо-данные (anna@eventally.test / ivan@eventally.test, пароль password123)
bin/dev              # сервер на http://localhost:3000
```

## Тесты

```bash
bin/rails db:test:prepare   # один раз: создать тестовую базу
bin/rails test              # все тесты
bin/rails test test/models/order_test.rb   # один файл
```

Модели: `User`, `Event`, `TicketType`, `Order`, `Ticket`. Тесты — Minitest + фикстуры в `test/fixtures`.

## 📄 Лицензия

MIT