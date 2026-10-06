class FavoritesController < ApplicationController
  before_action :authenticate_user!

  def index
    keys = current_user.favorites.order(created_at: :desc).pluck(:event_key)
    @upcoming, @past = Favorite.resolve(keys).partition { |event| !event.past? }
    @upcoming.sort_by!(&:starts_at)
  end

  def create
    current_user.favorites.find_or_create_by!(event_key: params[:key])
    head :no_content
  rescue ActiveRecord::RecordNotUnique
    head :no_content
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_content
  end

  def destroy
    current_user.favorites.where(event_key: params[:key]).delete_all
    head :no_content
  end
end
