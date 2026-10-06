class MyTicketsController < ApplicationController
  before_action :authenticate_user!

  def index
    tickets = current_user.tickets
                          .joins(ticket_type: :event)
                          .includes(:order, ticket_type: { event: :organizer })
                          .order(Event.arel_table[:starts_at], :created_at)

    groups = tickets.group_by { |ticket| ticket.ticket_type.event }
    @upcoming, @past = groups.partition { |event, _| !event.past? }
  end
end
