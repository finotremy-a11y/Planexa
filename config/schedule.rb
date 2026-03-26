# config/schedule.rb
# Générer le crontab : bundle exec whenever --update-crontab
# Supprimer le crontab : bundle exec whenever --clear-crontab

set :output, "log/cron.log"
set :environment, :production

# Chaque jour à 6h00 : suspendre les entreprises en retard de paiement > 7 jours
every 1.day, at: "6:00 am" do
  runner "SuspendOverdueCompaniesJob.perform_later"
end

# Chaque jour à 8h00 : rappel fin d'essai dans 3 jours
every 1.day, at: "8:00 am" do
  runner "TrialEndingReminderJob.perform_later"
end

# Chaque lundi à 8h30 : recap hebdomadaire de performance entreprise
every :monday, at: "8:30 am" do
  runner "WeeklyCompanyPerformanceEmailJob.perform_later"
end
