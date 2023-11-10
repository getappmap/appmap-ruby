require "active_job"

task count_users: :environment do
  FileUtils.rm_f PrintUserCountJob::FILENAME

  # Queue the job
  PrintUserCountJob.perform_later

  # Wait for the job to complete
  until File.exist?(PrintUserCountJob::FILENAME)
    sleep 0.1
  end
  count = File.read(PrintUserCountJob::FILENAME).to_i
  puts "User count: #{count}"
  sleep 1
end
