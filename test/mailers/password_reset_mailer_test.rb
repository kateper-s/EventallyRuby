require "test_helper"

class PasswordResetMailerTest < ActionMailer::TestCase
  test "письмо со ссылкой на сброс пароля" do
    user = users(:ivan)

    assert_emails 1 do
      user.send_reset_password_instructions
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal ["ivan@example.com"], mail.to
    assert_equal "Восстановление пароля", mail.subject
    assert_match "Задать новый пароль", mail.body.to_s
    assert_match %r{http://www\.example\.com/users/password/edit\?reset_password_token=\S+}, mail.body.to_s
  end

  test "токен в письме открывает форму смены пароля" do
    user = users(:ivan)
    token = user.send_reset_password_instructions

    assert_equal user, User.with_reset_password_token(token)
    assert_not_equal token, user.reload.reset_password_token
  end

  test "после смены пароля приходит уведомление" do
    user = users(:ivan)

    assert_emails 1 do
      user.update!(password: "newpassword1", password_confirmation: "newpassword1")
    end
    assert_equal "Пароль изменён", ActionMailer::Base.deliveries.last.subject
  end
end
