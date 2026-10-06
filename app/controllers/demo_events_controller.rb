class DemoEventsController < ApplicationController
  def show
    @event = DemoEvent.find(params[:id])
    @related = @event.related
    render "events/show"
  end
end
