module AppMap
  class HookLog
    LOG = (ENV['APPMAP_DEBUG'] == 'true' || ENV['DEBUG'] == 'true')
    LOG_HOOK = (ENV['DEBUG_HOOK'] == 'true' || ENV['APPMAP_LOG_HOOK'] == 'true')
    LOG_HOOK_FILE = (ENV['APPMAP_LOG_HOOK_FILE'] || 'appmap_hook.log')

    def initialize
      @file_handle = self.class.send :open_log_file
      @elapsed = Hash.new { |h, k| h[k] = [] }

      at_exit do
        @file_handle.puts 'Elapsed time:'
        @elapsed.keys.each do |k|
          @file_handle.puts "#{k}:\t#{@elapsed[k].sum}"
        end
        @file_handle.flush
        @file_handle.close
      end
    end

    def start_time(timer)
      @elapsed[timer] << [Util.gettime]
    end

    def end_time(timer)
      unless @elapsed[timer].last.is_a?(Array)
        warn "AppMap: Unbalanced timing data in hook log"
        @elapsed[timer].pop
        return
      end

      @elapsed[timer][-1] = Util.gettime - @elapsed[timer].last[0]
    end

    class << self
      def enabled?
        LOG || LOG_HOOK
      end

      def builtin(class_name, &block)
        return yield unless enabled?

        begin
          log "eager\tbegin\tInitiating eager hook for #{class_name}"
          @hook_log.start_time :eager

          yield
        ensure
          @hook_log.end_time :eager
          log "eager\tend\tCompleted eager hook for #{class_name}"
        end
      end

      def on_load(location, &block)
        return yield unless enabled?

        begin
          log "on-load\tbegin\tInitiating on-load hook for class or module defined at location #{location}"
          @hook_log.start_time :on_load

          yield
        ensure
          @hook_log.end_time :on_load
          log "on-load\tend\tCompleted on-load hook for location #{location}"
        end
      end

      def load_error(name, msg)
        log "load_error\t#{name}\t#{msg}"
      end

      def log(msg)
        unless HookLog.enabled?
          warn "AppMap: HookLog is not enabled. Disregarding message #{msg}"
          return
        end

        @hook_log ||= HookLog.new
        @hook_log.log msg
      end

      protected def open_log_file
        if LOG_HOOK_FILE == 'stderr'
          $stderr
        else
          File.open(LOG_HOOK_FILE, 'w')
        end
      end
    end

    def log(msg)
      if LOG_HOOK_FILE == 'stderr'
        msg = "AppMap: #{msg}"
      end
      msg = "#{Util.gettime}\t#{msg}"
      @file_handle.puts(msg)
    end
  end
end
