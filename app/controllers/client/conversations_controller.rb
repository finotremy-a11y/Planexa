# frozen_string_literal: true

class Client::ConversationsController < Client::BaseController
  before_action :sync_conversations_from_appointments!, only: :index

  def index
    @conversations = current_user.client_conversations
                                 .includes(:company, :client_user, conversation_messages: [ photos_attachments: :blob ])
                                 .recent
    @total_unread_count = @conversations.sum { |conversation| conversation.unread_count_for(current_user) }
  end

  def show
    @conversation = current_user.client_conversations
                                .includes(:company, :client_user)
                                .find(params[:id])
    @conversation.mark_read_by!(current_user)
    @messages = @conversation.conversation_messages.includes(:sender, photos_attachments: :blob)
    @message = ConversationMessage.new
  end

  private

  def sync_conversations_from_appointments!
    company_ids = current_user.client_appointments
                              .where.not(company_id: nil)
                              .distinct
                              .pluck(:company_id)

    company_ids.each do |company_id|
      Conversation.ensure_between!(
        company: Company.find(company_id),
        client_user: current_user
      )
    end
  end
end
