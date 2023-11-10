class Job
  # @label job.perform
  def perform
    do_work
  end

  protected_methods

  def do_work
    puts "Doing work"
    sleep 0.001
  end
end
