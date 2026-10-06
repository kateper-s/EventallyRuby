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

## Почта (восстановление пароля)

Скопируйте `.env.example` в `.env` и заполните SMTP:

```bash
SMTP_ADDRESS=smtp.yandex.ru
SMTP_PORT=465
SMTP_USERNAME=you@yandex.ru
SMTP_PASSWORD=пароль_приложения
```

Без `SMTP_USERNAME` письма не отправляются, их текст виден в логе сервера.

## Тесты

```bash
bin/rails db:test:prepare   # один раз: создать тестовую базу
bin/rails test              # все тесты
bin/rails test test/models/order_test.rb   # один файл
```

Модели: `User`, `Event`, `TicketType`, `Order`, `Ticket`. Тесты — Minitest + фикстуры в `test/fixtures`.

## 📄 Лицензия

MIT