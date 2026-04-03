# frozen_string_literal: true

class ConversationMessage < ApplicationRecord
  MAX_PHOTO_SIZE = 8.megabytes

  belongs_to :conversation, touch: true
  belongs_to :sender, class_name: "User"

  has_many_attached :photos

  validates :body, length: { maximum: 2_000 }
  validate :body_or_photo_present
  validate :sender_belongs_to_conversation
  validate :photos_must_be_images
  validate :photos_size_limit

  after_create_commit :broadcast_message
  after_create_commit :mark_sender_read
  after_create_commit :notify_recipient

  scope :recent, -> { order(created_at: :asc) }

  private

  def body_or_photo_present
    return if body.present? || photos.attached?

    errors.add(:base, "Le message ne peut pas etre vide")
  end

  def sender_belongs_to_conversation
    return if conversation.blank? || sender.blank?

    is_company_sender = conversation.company.user_id == sender_id
    is_client_sender = conversation.client_user_id == sender_id
    return if is_company_sender || is_client_sender

    errors.add(:sender, "n'est pas autorise pour cette conversation")
  end

  def photos_must_be_images
    return unless photos.attached?

    photos.each do |photo|
      next if photo.content_type.to_s.start_with?("image/")

      errors.add(:photos, "doivent etre des images")
    end
  end

  def photos_size_limit
    return unless photos.attached?

    photos.each do |photo|
      next if photo.byte_size <= MAX_PHOTO_SIZE

      errors.add(:photos, "ne peuvent pas depasser 8 Mo")
    end
  end

  def broadcast_message
    broadcast_append_to(
      conversation.stream_name,
      target: "messages_list",
      partial: "conversation_messages/conversation_message",
      locals: { message: self }
    )
  end

  def mark_sender_read
    conversation.mark_read_by!(sender)
  end

  def notify_recipient
    recipient = if sender_id == conversation.client_user_id
                  conversation.company.user
                else
                  conversation.client_user
                end
    return unless recipient

    sender_name = sender.full_name
    preview = body.present? ? body.truncate(80) : "Photo envoyee"

    PushNotificationService.notify_user(
      user: recipient,
      title: "Nouveau message",
      body: "#{sender_name}: #{preview}",
      data: {
        url: sender_id == conversation.client_user_id ? "/company/messagerie/#{conversation.id}" : "/client/messagerie/#{conversation.id}",
        company_id: conversation.company_id,
        type: "conversation.message"
      }
    )
  end
end
