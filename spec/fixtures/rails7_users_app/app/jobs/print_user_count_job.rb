class PrintUserCountJob < ApplicationJob
  FILENAME = "tmp/user_count.txt"

  def perform
    count = User.count
    File.write FILENAME, count
  end
end
