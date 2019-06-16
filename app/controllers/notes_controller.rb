class NotesController < ApplicationController
  before_action :find_commentable, only: %w[create]

  def create
    @note = @commentable.notes.build(note_params)
    if @note.save
      # render @note, layout: false, status: :created
      render json: { note: render_to_string(partial: 'notes/note', locals: { note: @note }) }
    else
      render json: { error: @note.errors.full_messages.join(', ') }
    end
  end

  private

  def note_params
    params.require(:note).permit(:text)
  end

  def find_commentable
    resource, id = request.path.split('/')[1, 2]
    begin
      @commentable = resource.singularize.classify.constantize.find(id)
    rescue ActiveRecord::RecordNotFound
      return head :bad_request
    end
  end
end
