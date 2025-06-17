namespace :setup do
  desc "Create an admin user"
  task admin: :environment do
    User.create!(
      email_address: ENV.fetch("ADMIN_EMAIL", "admin@example.org"),
      password: ENV.fetch("ADMIN_PASSWORD", "password"),
      admin: true
    )

    Rails.logger.info "Admin user created: #{ENV.fetch("ADMIN_EMAIL", "admin@example.com")}"
  end
end
