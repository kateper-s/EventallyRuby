class MyEventsController < ApplicationController
  TABS = {
    "upcoming" => "Предстоящие",
    "drafts"   => "Черновики",
    "past"     => "Прошедшие"
  }.freeze

  before_action :authenticate_user!

  def index
    authorize Event, :manage?

    @tab = params[:tab].presence_in(TABS.keys) || "upcoming"
    events = current_user.organized_events.includes(:ticket_types, :organizer)
    @counts = TABS.keys.index_with { |tab| filter(events, tab).count }
    @events = filter(events, @tab)
  end

  private

  def filter(events, tab)
    now = Time.current

    case tab
    when "drafts" then events.where(published: false).order(:starts_at)
    when "past"   then events.where(published: true, starts_at: ...now).order(starts_at: :desc)
    else               events.where(published: true, starts_at: now..).order(:starts_at)
    end
  end
end
