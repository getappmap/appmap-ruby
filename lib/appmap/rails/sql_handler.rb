# frozen_string_literal: true

require 'appmap/trace/tracer'

module AppMap
  module Rails
    class SQLHandler
      class SQLCall < AppMap::Trace::MethodEvent
        attr_accessor :payload

        def initialize(path, lineno, payload)
          super AppMap::Trace::MethodEvent.next_id, :call, SQLHandler, :call, path, lineno, false, Thread.current.object_id

          self.payload = payload
        end

        def to_h
          super.tap do |h|
            h[:sql_query] = {
              sql: payload[:sql],
              database_type: payload[:database_type]
            }.tap do |sql_query|
              %i[server_version explain_sql].each do |attribute|
                sql_query[attribute] = payload[attribute] if payload[attribute]
              end
            end
          end
        end
      end

      class SQLReturn < AppMap::Trace::MethodReturnIgnoreValue
        def initialize(path, lineno, parent_id, elapsed)
          super AppMap::Trace::MethodEvent.next_id, :return, SQLHandler, :call, path, lineno, false, Thread.current.object_id

          self.parent_id = parent_id
          self.elapsed = elapsed
        end
      end

      module SQLExaminer
        class << self
          def examine(payload, sql:)
            return unless (examiner = build_examiner)

            payload[:server_version] = examiner.server_version
            payload[:database_type] = examiner.database_type.to_s
          end

          protected

          def build_examiner
            if defined?(Sequel)
              SequelExaminer.new
            elsif defined?(ActiveRecord)
              ActiveRecordExaminer.new
            end
          end
        end

        class SequelExaminer
          def server_version
            Sequel::Model.db.server_version
          end

          def database_type
            Sequel::Model.db.database_type.to_sym
          end

          def execute_query(sql)
            Sequel::Model.db[sql].all
          end
        end

        class ActiveRecordExaminer
          def server_version
            case database_type
            when :postgres
              ActiveRecord::Base.connection.postgresql_version
            else
              warn "Unable to determine database version for #{database_type.inspect}"
            end
          end

          def database_type
            return :postgres if ActiveRecord::Base.connection.respond_to?(:postgresql_version)

            ActiveRecord::Base.connection.adapter_name.downcase.to_sym
          end

          def execute_query(sql)
            ActiveRecord::Base.connection.execute(sql).inject([]) { |memo, r| memo << r; memo }
          end
        end
      end

      def call(_, started, finished, _, payload) # (name, started, finished, unique_id, payload)
        return if AppMap::Trace.tracers.empty?

        reentry_key = "#{self.class.name}#call"
        return if Thread.current[reentry_key] == true

        Thread.current[reentry_key] = true
        begin
          sql = payload[:sql].strip
          sql_upper = sql.upcase

          return unless WHITELIST.find { |keyword| sql_upper.index(keyword) == 0 }

          # Detect whether a function call within a specified filename is present in the call stack.
          find_in_backtrace = lambda do |file_name, function_name = nil|
            Thread.current.backtrace.find do |line|
              tokens = line.split(':')
              matches_file = tokens.find { |t| t.rindex(file_name) == (t.length - file_name.length) }
              matches_function = function_name.nil? || tokens.find { |t| t == "in `#{function_name}'" }
              matches_file && matches_function
            end
          end

          # Ignore SQL calls which are made while establishing a new connection.
          #
          # Example:
          # /path/to/ruby/2.6.0/gems/sequel-5.20.0/lib/sequel/connection_pool.rb:122:in `make_new'
          return if find_in_backtrace.call('lib/sequel/connection_pool.rb', 'make_new')
          # lib/active_record/connection_adapters/abstract/connection_pool.rb:811:in `new_connection'
          return if find_in_backtrace.call('lib/active_record/connection_adapters/abstract/connection_pool.rb', 'new_connection')

          # Ignore SQL calls which are made while inspecting the DB schema.
          #
          # Example:
          # /path/to/ruby/2.6.0/gems/sequel-5.20.0/lib/sequel/model/base.rb:812:in `get_db_schema'
          return if find_in_backtrace.call('lib/sequel/model/base.rb', 'get_db_schema')
          # /usr/local/bundle/gems/activerecord-5.2.3/lib/active_record/model_schema.rb:466:in `load_schema!'
          return if find_in_backtrace.call('lib/active_record/model_schema.rb', 'load_schema!')
          return if find_in_backtrace.call('lib/active_model/attribute_methods.rb', 'define_attribute_methods')
          return if find_in_backtrace.call('lib/active_record/connection_adapters/schema_cache.rb')

          SQLExaminer.examine payload, sql: sql

          call = SQLCall.new(__FILE__, __LINE__, payload)
          AppMap::Trace.tracers.record_event(call)
          AppMap::Trace.tracers.record_event(SQLReturn.new(__FILE__, __LINE__, call.id, finished - started))
        ensure
          Thread.current[reentry_key] = nil
        end
      end

      WHITELIST = %w[SELECT INSERT UPDATE DELETE].freeze
    end
  end
end
