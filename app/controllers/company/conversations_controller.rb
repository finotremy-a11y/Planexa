# frozen_string_literal: true

class Company::ConversationsController < Company::BaseController
  before_action :sync_conversations_from_appointments!, only: :index

  def index
    @conversations = @company.conversations
                             .includes(:company, :client_user, conversation_messages: [ photos_attachments: :blob ])
                             .recent
    @total_unread_count = @conversations.sum { |conversation| conversation.unread_count_for(current_user) }
  end

  def show
    @conversation = @company.conversations.includes(:client_user, :company).find(params[:id])
    @conversation.mark_read_by!(current_user)
    @messages = @conversation.conversation_messages.includes(:sender, photos_attachments: :blob)
    @message = ConversationMessage.new
  end

  private

  def sync_conversations_from_appointments!
    client_ids = @company.appointments
                         .where.not(client_user_id: nil)
                         .distinct
                         .pluck(:client_user_id)

    client_ids.each do |client_id|
      Conversation.ensure_between!(
        company: @company,
        client_user: User.find(client_id)
      )
    end
  end
end
