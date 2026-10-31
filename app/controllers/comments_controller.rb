class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event

  def create
    @comment = @event.comments.build(body: comment_params[:body], user: current_user)
    authorize @comment

    if @comment.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("comments", partial: "comments/comment", locals: { comment: @comment }),
            turbo_stream.update("comments_count", partial: "comments/count", locals: { count: @event.comments.count }),
            turbo_stream.replace("comment_form", partial: "comments/form", locals: { event: @event, comment: Comment.new })
          ]
        end
        format.html { redirect_to event_path(@event, anchor: "discussion") }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("comment_form", partial: "comments/form",
                                                    locals: { event: @event, comment: @comment }),
                 status: :unprocessable_content
        end
        format.html { redirect_to event_path(@event, anchor: "discussion"), alert: @comment.errors.full_messages.to_sentence }
      end
    end
  end

  def destroy
    comment = @event.comments.find(params[:id])
    authorize comment
    comment.destroy!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(comment),
          turbo_stream.update("comments_count", partial: "comments/count", locals: { count: @event.comments.count })
        ]
      end
      format.html { redirect_to event_path(@event, anchor: "discussion") }
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def comment_params
    params.fetch(:comment, {}).permit(:body)
  end
end
