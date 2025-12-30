# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'set'
require 'pangea/resources/types'
require_relative 'parameter'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS RDS Cluster Parameter Group resources
        class RdsClusterParameterGroupAttributes < Dry::Struct
          AURORA_MYSQL_PARAMETERS = Set.new(%w[
            innodb_buffer_pool_size max_connections slow_query_log long_query_time innodb_lock_wait_timeout
            interactive_timeout wait_timeout max_allowed_packet innodb_flush_log_at_trx_commit innodb_file_per_table
            general_log binlog_format innodb_autoinc_lock_mode character_set_server collation_server time_zone
            sql_mode innodb_log_buffer_size read_buffer_size sort_buffer_size join_buffer_size tmp_table_size
            max_heap_table_size thread_cache_size table_open_cache innodb_thread_concurrency innodb_read_io_threads
            innodb_write_io_threads
          ]).freeze

          AURORA_POSTGRESQL_PARAMETERS = Set.new(%w[
            shared_buffers max_connections work_mem maintenance_work_mem effective_cache_size random_page_cost
            seq_page_cost log_statement log_min_duration_statement log_connections log_disconnections log_lock_waits
            log_temp_files checkpoint_timeout checkpoint_completion_target wal_buffers default_statistics_target
            effective_io_concurrency max_wal_size min_wal_size autovacuum autovacuum_max_workers autovacuum_naptime
            autovacuum_vacuum_threshold autovacuum_analyze_threshold timezone log_timezone datestyle lc_messages
            lc_monetary lc_numeric lc_time statement_timeout idle_in_transaction_session_timeout
          ]).freeze

          attribute :name, Resources::Types::String.optional
          attribute :name_prefix, Resources::Types::String.optional
          attribute :family, Resources::Types::String.enum(
            'aurora-mysql5.7', 'aurora-mysql8.0',
            'aurora-postgresql10', 'aurora-postgresql11', 'aurora-postgresql12',
            'aurora-postgresql13', 'aurora-postgresql14', 'aurora-postgresql15'
          )
          attribute :description, Resources::Types::String
          attribute :parameter, Resources::Types::Array.of(DbParameter).default([].freeze)
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          def self.new(attributes = {})
            attrs = super(attributes)
            raise Dry::Struct::Error, "Cannot specify both 'name' and 'name_prefix'" if attrs.name && attrs.name_prefix

            parameter_names = attrs.parameter.map(&:name)
            duplicates = parameter_names.select { |n| parameter_names.count(n) > 1 }.uniq
            raise Dry::Struct::Error, "Duplicate parameter names found: #{duplicates.join(', ')}" if duplicates.any?

            invalid_params = validate_parameters_for_family(attrs.family, attrs.parameter)
            raise Dry::Struct::Error, "Invalid parameters for family '#{attrs.family}': #{invalid_params.join(', ')}" if invalid_params.any?

            attrs
          end

          def self.validate_parameters_for_family(family, parameters)
            parameters.each_with_object([]) do |param, invalid|
              valid_params = family.start_with?('aurora-mysql') ? AURORA_MYSQL_PARAMETERS : AURORA_POSTGRESQL_PARAMETERS
              invalid << param.name unless valid_params.include?(param.name)
            end
          end

          def engine_type
            return 'mysql' if family.start_with?('aurora-mysql')
            return 'postgresql' if family.start_with?('aurora-postgresql')

            'unknown'
          end

          def engine_version
            case family
            when 'aurora-mysql5.7' then '5.7'
            when 'aurora-mysql8.0' then '8.0'
            when /^aurora-postgresql(\d+)/ then ::Regexp.last_match(1)
            else 'unknown'
            end
          end

          def is_mysql_family? = family.start_with?('aurora-mysql')
          def is_postgresql_family? = family.start_with?('aurora-postgresql')
          def immediate_parameters = parameter.select(&:requires_immediate_application?)
          def reboot_parameters = parameter.select(&:requires_reboot?)
          def has_immediate_parameters? = immediate_parameters.any?
          def has_reboot_parameters? = reboot_parameters.any?
          def get_parameter(name) = parameter.find { |p| p.name == name }
          def has_parameter?(name) = !get_parameter(name).nil?
          def parameter_names = parameter.map(&:name)

          def configuration_summary
            summary = ["Engine: #{engine_type}", "Version: #{engine_version}", "Parameters: #{parameter.count}"]
            summary << "Immediate changes: #{immediate_parameters.count}" if has_immediate_parameters?
            summary << "Reboot required: #{reboot_parameters.count}" if has_reboot_parameters?
            summary.join('; ')
          end
        end
      end
    end
  end
end
