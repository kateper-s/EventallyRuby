require "test_helper"

class UserTest < ActiveSupport::TestCase
  def build_user(**attrs)
    User.new({ name: "Мария", email: "maria@example.com", password: "secret123",
               password_confirmation: "secret123" }.merge(attrs))
  end

  test "валиден с корректными данными" do
    assert build_user.valid?
  end

  test "имя обязательно" do
    user = build_user(name: "")
    assert_not user.valid?
    assert user.errors.of_kind?(:name, :blank)
  end

  test "имя не длиннее 60 символов" do
    assert_not build_user(name: "а" * 61).valid?
    assert build_user(name: "а" * 60).valid?
  end

  test "по умолчанию роль — посетитель" do
    user = User.new
    assert user.visitor?
    assert_not user.organizer?
  end

  test "неизвестная роль даёт ошибку валидации, а не исключение" do
    user = build_user(role: "admin")
    assert_not user.valid?
    assert user.errors.of_kind?(:role, :inclusion)
  end

  test "email уникален без учёта регистра" do
    user = build_user(email: "ANNA@example.com")
    assert_not user.valid?
    assert user.errors.of_kind?(:email, :taken)
  end

  test "пароль не короче 6 символов" do
    user = build_user(password: "12345", password_confirmation: "12345")
    assert_not user.valid?
    assert user.errors.of_kind?(:password, :too_short)
  end

  test "пароль хранится только в виде хеша" do
    user = build_user
    user.save!
    assert_not_equal "secret123", user.encrypted_password
    assert user.valid_password?("secret123")
    assert_not user.valid_password?("wrong")
  end

  test "скоупы ролей" do
    assert_includes User.organizer, users(:anna)
    assert_not_includes User.organizer, users(:ivan)
  end

  test "организатор видит свои события, посетитель — свои билеты" do
    assert_includes users(:anna).organized_events, events(:rails_conf)
    assert_not_includes users(:anna).organized_events, events(:ruby_meetup)
    assert_equal 4, users(:ivan).tickets.count
  end
end
