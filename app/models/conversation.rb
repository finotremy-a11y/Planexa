# frozen_string_literal: true

class Conversation < ApplicationRecord
  belongs_to :company
  belongs_to :client_user, class_name: "User"

  has_many :conversation_messages, -> { order(created_at: :asc) }, dependent: :destroy

  validates :client_user_id, uniqueness: { scope: :company_id }
  validate :client_user_must_have_client_role

  scope :recent, -> { order(updated_at: :desc) }

  def stream_name
    "conversation_#{id}_messages"
  end

  def title_for_company
    client_user.full_name
  end

  def title_for_client
    company.name
  end

  def last_message
    conversation_messages.order(created_at: :desc).first
  end

  def mark_read_by!(user)
    return unless user

    if user.id == client_user_id
      update_column(:client_last_read_at, Time.current)
    elsif user.id == company.user_id
      update_column(:company_last_read_at, Time.current)
    end
  end

  def unread_count_for(user)
    return 0 unless user

    relation = conversation_messages.where.not(sender_id: user.id)
    last_read_at = last_read_at_for(user)
    relation = relation.where("created_at > ?", last_read_at) if last_read_at.present?
    relation.count
  end

  def self.ensure_between!(company:, client_user:)
    find_or_create_by!(company: company, client_user: client_user)
  end

  private

  def last_read_at_for(user)
    return client_last_read_at if user.id == client_user_id
    return company_last_read_at if user.id == company.user_id

    nil
  end

  def client_user_must_have_client_role
    return if client_user.blank? || client_user.client?

    errors.add(:client_user, "doit etre un client")
  end
end
