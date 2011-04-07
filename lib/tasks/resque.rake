# This also makes all resque rake tasks load the Rails environment first
task "resque:setup" => :environment do
  USE_RESQUE_FOR_TASKS = true
  puts "Setting up resque in #{Rails.env} environment..."
  ENV["QUEUE"] = "abacus_statistics" if ENV["QUEUE"].blank?
  puts "Using queues: #{ENV['QUEUE']}"
end
