# This is an internal tool

if defined?(ActiveRecord)
  class ActiveRecord::ConnectionAdapters::ConnectionPool
    # Based on ConnectionPool#stat
    def enhanced_stats
      synchronize do
        current_context = ActiveSupport::IsolatedExecutionState.context
        {
          size: size,
          connections: @connections.size,
          busy: @connections.count { |c| c.in_use? && c.owner.alive? },
          dead: @connections.count { |c| c.in_use? && !c.owner.alive? },
          idle: @connections.count { |c| !c.in_use? },
          waiting: num_waiting_in_queue,
          checkout_timeout: checkout_timeout,

          # Added stats
          isolation_level: ActiveSupport::IsolatedExecutionState.isolation_level,
          thread_id: Thread.current.object_id,
          in_use: @connections.select(&:in_use?).map(&:object_id),
          owner_alive: @connections.select { |c| c.owner&.alive? }.map(&:object_id),
          owner: @connections.map { |c| c.owner.inspect },
          current_context: current_context.inspect
        }
      end
    end
  end
end
