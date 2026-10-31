require "test_helper"

class AccountFlowTest < ActionDispatch::IntegrationTest
  test "регистрация с ошибками не создаёт пользователя и показывает причины" do
    assert_no_difference -> { User.count } do
      post user_registration_path, params: { user: {
        name: "", email: users(:anna).email, role: "visitor",
        password: "123", password_confirmation: "456"
      } }
    end

    assert_response :unprocessable_content
    assert_select "#error_explanation li", minimum: 3
  end

  test "вход с неверным паролем не пускает, с верным — пускает" do
    post user_session_path, params: { user: { email: users(:ivan).email, password: "wrong-password" } }
    follow_redirect! if response.redirect?
    assert_match(/Неверный .* или пароль/, response.body)

    get my_tickets_path
    assert_redirected_to new_user_session_path

    post user_session_path, params: { user: { email: users(:ivan).email, password: "password123" } }
    assert_redirected_to my_tickets_path
    follow_redirect!
    assert_response :success
  end

  test "восстановление пароля по письму от запроса до входа с новым паролем" do
    user = users(:ivan)

    get new_user_password_path
    assert_response :success

    assert_emails 1 do
      post user_password_path, params: { user: { email: user.email } }
    end
    assert_redirected_to new_user_session_path

    mail = ActionMailer::Base.deliveries.last
    assert_equal [user.email], mail.to
    token = mail.body.to_s[/reset_password_token=([\w\-]+)/, 1]
    assert token.present?

    get edit_user_password_path(reset_password_token: token)
    assert_response :success

    put user_password_path, params: { user: {
      reset_password_token: token, password: "newsecret1", password_confirmation: "newsecret1"
    } }
    assert_response :redirect
    follow_redirect!
    assert_match "Пароль изменён", response.body

    delete destroy_user_session_path

    post user_session_path, params: { user: { email: user.email, password: "password123" } }
    follow_redirect! if response.redirect?
    assert_match(/Неверный .* или пароль/, response.body)

    post user_session_path, params: { user: { email: user.email, password: "newsecret1" } }
    assert_redirected_to root_path
  end

  test "для несуществующего email ответ такой же, но письмо не уходит" do
    assert_no_emails do
      post user_password_path, params: { user: { email: "nobody@example.com" } }
    end
    assert_redirected_to new_user_session_path
  end
end
