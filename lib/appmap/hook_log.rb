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
      @elapsed[timer] << [Time.now.to_f]
    end

    def end_time(timer)
      @elapsed[timer][-1] = Time.now.to_f - @elapsed[timer].last[0]
    end

    class << self
      def enabled?
        LOG || LOG_HOOK
      end

      def builtin_begin(class_name, method_name)
        log "builtin\tbegin\tInitiating hook for builtin #{class_name} #{method_name}"
        @hook_log.start_time :builtin
      end

      def builtin_end(class_name, method_name)
        @hook_log.end_time :builtin
        log "builtin\tend\tCompleted hook for builtin #{class_name} #{method_name}"
      end

      def usercode_begin(location)
        log "usercode\tbegin\tClass or module defined at location #{location}"
        @hook_log.start_time :usercode
      end

      def usercode_end(location)
        @hook_log.end_time :usercode
        log "usercode\tend\tCompleted location #{location}"
      end

      def log(msg)
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
      msg = "#{Time.new.to_f}\t#{msg}"
      @file_handle.puts(msg)
    end
  end
end
