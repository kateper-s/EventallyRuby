class EventsController < ApplicationController
  before_action :authenticate_user!, only: %i[new create]

  def show
    @event = Event.includes(:organizer, :ticket_types).find(params[:id])
    authorize @event
    @related = @event.related
    if user_signed_in?
      @my_tickets_count = current_user.tickets.merge(Order.paid).where(ticket_type: @event.ticket_types).count
    else
      store_location_for(:user, request.fullpath)
    end
  end

  def new
    @event = current_user.organized_events.build(published: true)
    @event.ticket_types.build(name: "Стандарт")
    authorize @event
  end

  def create
    @event = current_user.organized_events.build(event_params)
    authorize @event

    if @event.save
      redirect_to @event, notice: "Событие создано"
    else
      @event.ticket_types.build(name: "Стандарт") if @event.ticket_types.empty?
      render :new, status: :unprocessable_content
    end
  end

  private

  def event_params
    params.require(:event).permit(
      :title, :description, :category, :starts_at, :ends_at, :venue, :city, :published,
      ticket_types_attributes: %i[name price quota]
    )
  end
end
