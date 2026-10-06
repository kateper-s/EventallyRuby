class OrdersController < ApplicationController
  MAX_QUANTITY = 10

  before_action :authenticate_user!

  def create
    event = Event.find(params[:event_id])
    authorize event, :buy?

    ticket_type = event.ticket_types.find_by(id: order_params[:ticket_type_id])
    return redirect_to(event, alert: "Выберите тип билета") unless ticket_type

    quantity = order_params[:quantity].to_i
    unless quantity.between?(1, MAX_QUANTITY)
      return redirect_to(event, alert: "Можно купить от 1 до #{MAX_QUANTITY} билетов за раз")
    end

    order = Order.purchase!(user: current_user, ticket_type: ticket_type, quantity: quantity)
    redirect_to my_tickets_path, notice: "Готово! #{helpers.ru_plural(order.tickets.size, 'билет', 'билета', 'билетов')} на «#{event.title}» уже в разделе «Мои билеты»"
  rescue Order::SoldOut
    redirect_to event, alert: "Не хватает мест: осталось #{ticket_type.reload.available}"
  rescue Order::PurchaseError => e
    redirect_to event, alert: e.message
  end

  private

  def order_params
    params.fetch(:order, {}).permit(:ticket_type_id, :quantity)
  end
end
