# frozen_string_literal: true

require 'appmap/event'
require 'appmap/hook/method'
require 'appmap/util'

module AppMap
  module Handler
    module Rails
      class SQLHandler
        class SQLCall < AppMap::Event::MethodCall
          attr_accessor :payload

          def initialize(payload)
            super AppMap::Event.next_id_counter, :call, Thread.current.object_id

            self.payload = payload
          end

          def to_h
            super.tap do |h|
              h[:sql_query] = {
                sql: payload[:sql],
                database_type: payload[:database_type]
              }.tap do |sql_query|
                sql_query[:query_plan] = payload[:query_plan] if payload[:query_plan]
                %i[server_version].each do |attribute|
                  sql_query[attribute] = payload[attribute] if payload[attribute]
                end
              end
            end
          end
        end

        class SQLReturn < AppMap::Event::MethodReturnIgnoreValue
          def initialize(parent_id, elapsed)
            super AppMap::Event.next_id_counter, :return, Thread.current.object_id

            self.parent_id = parent_id
            self.elapsed = elapsed
          end
        end

        module SQLExaminer
          class << self
            def examine(payload, sql:)
              return unless (examiner = build_examiner)

              in_transaction = examiner.in_transaction?

              if AppMap.explain_queries? && examiner.database_type == :postgres
                if sql =~ /\A(SELECT|INSERT|UPDATE|DELETE|WITH)/i
                  savepoint_established = \
                    begin
                      tx_query = in_transaction ? 'SAVEPOINT appmap_sql_examiner' : 'BEGIN TRANSACTION'
                      examiner.execute_query tx_query
                      true
                    rescue
                      # Probably: Sequel::DatabaseError: PG::InFailedSqlTransaction
                      warn $!
                      false
                    end

                  if savepoint_established
                    plan = nil
                    begin
                      plan = examiner.execute_query(%(EXPLAIN #{sql}))
                      payload[:query_plan] = plan.map { |line| line[:'QUERY PLAN'] }.join("\n")
                    rescue
                      warn "(appmap) Error explaining query: #{$!}"
                    ensure
                      tx_query = in_transaction ? 'ROLLBACK TO SAVEPOINT appmap_sql_examiner' : 'ROLLBACK'
                      examiner.execute_query tx_query
                    end
                  end
                end
              end

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
              # Queries the database, therefore this is pretty unsafe to do inside of a hook.
              # As a result, this is not being used at the moment.
              Sequel::Model.db.server_version
            end

            def database_type
              Sequel::Model.db.database_type.to_sym
            end

            def in_transaction?
              Sequel::Model.db.in_transaction?
            end

            def execute_query(sql)
              Sequel::Model.db[sql].all
            end
          end

          class ActiveRecordExaminer
            @@db_version_warning_issued = {}
            
            def issue_warning
              db_type = database_type
              return if @@db_version_warning_issued[db_type]
              warn("AppMap: Unable to determine database version for #{db_type.inspect}") 
              @@db_version_warning_issued[db_type] = true
            end
            
            def server_version
              ActiveRecord::Base.connection.try(:database_version) || issue_warning
            end

            def database_type
              type = ActiveRecord::Base.connection.adapter_name.downcase.to_sym
              type = :postgres if type == :postgresql

              type
            end

            def in_transaction?
              ActiveRecord::Base.connection.open_transactions > 0
            end

            def execute_query(sql)
              ActiveRecord::Base.connection.execute(sql).to_a
            end
          end
        end

        def call(_, started, finished, _, payload) # (name, started, finished, unique_id, payload)
          return if AppMap.tracing.empty?

          return if Thread.current[AppMap::Hook::Method::HOOK_DISABLE_KEY] == true

          reentry_key = "#{self.class.name}#call"
          return if Thread.current[reentry_key] == true

          after_start_time = AppMap::Util.gettime()

          Thread.current[reentry_key] = true
          begin
            sql = payload[:sql].strip

            SQLExaminer.examine payload, sql: sql

            call = SQLCall.new(payload)
            AppMap.tracing.record_event(call)
            sql_return_event = SQLReturn.new(call.id, finished - started)
            sql_return_event.elapsed_instrumentation = AppMap::Util.gettime() - after_start_time
            AppMap.tracing.record_event(sql_return_event)
          ensure
            Thread.current[reentry_key] = nil
          end
        end
      end
    end
  end
end
