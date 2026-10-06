class DemoEventsController < ApplicationController
  def show
    demo = DemoEvent.find(params[:id])
    if (event = demo.imported_event)
      return redirect_to event
    end

    store_location_for(:user, request.fullpath) unless user_signed_in?
    @event = demo
    @related = @event.related
    render "events/show"
  end
end
