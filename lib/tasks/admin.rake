# frozen_string_literal: true

namespace :admin do
  desc "Bootstrap or update admin user from ADMIN_EMAIL and ADMIN_PASSWORD"
  task bootstrap: :environment do
    email = ENV.fetch("ADMIN_EMAIL", "admin@planifypro.fr").to_s.downcase.strip
    password = ENV.fetch("ADMIN_PASSWORD", "AdminPlanify2025!").to_s

    if email.blank? || password.blank?
      abort "ADMIN_EMAIL and ADMIN_PASSWORD must be present"
    end

    user = User.find_or_initialize_by(email: email)
    user.first_name = "Admin" if user.first_name.blank?
    user.last_name = "Planify" if user.last_name.blank?
    user.role = :admin
    user.password = password
    user.password_confirmation = password
    user.confirmed_at ||= Time.current

    if user.save
      puts "Admin ready: #{user.email} (role=#{user.role}, confirmed=#{user.confirmed?})"
    else
      abort "Failed to bootstrap admin: #{user.errors.full_messages.join(', ')}"
    end
  end
end
