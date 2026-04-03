# frozen_string_literal: true

class Company::ConversationMessagesController < Company::BaseController
  before_action :set_conversation

  def create
    @message = @conversation.conversation_messages.build(message_params)
    @message.sender = current_user

    if @message.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "message_form",
            partial: "company/conversations/form",
            locals: { conversation: @conversation, message: ConversationMessage.new }
          )
        end
        format.html { redirect_to company_conversation_path(@conversation), notice: "Message envoye." }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "message_form",
            partial: "company/conversations/form",
            locals: { conversation: @conversation, message: @message }
          ), status: :unprocessable_entity
        end
        format.html do
          @messages = @conversation.conversation_messages.includes(:sender, photos_attachments: :blob)
          render "company/conversations/show", status: :unprocessable_entity
        end
      end
    end
  end

  private

  def set_conversation
    @conversation = @company.conversations.find(params[:conversation_id])
  end

  def message_params
    params.require(:conversation_message).permit(:body, photos: [])
  end
end
