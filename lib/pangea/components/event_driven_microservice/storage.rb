# frozen_string_literal: true

module Pangea
  module Components
    module EventDrivenMicroservice
      # DynamoDB tables for event store and CQRS
      module Storage
        def create_event_store(name, component_attrs, component_tag_set)
          aws_dynamodb_table(component_resource_name(name, :event_store), {
            name: component_attrs.event_store.table_name,
            billing_mode: 'PAY_PER_REQUEST',
            hash_key: 'aggregate_id',
            range_key: 'sequence_number',
            attribute: event_store_attributes,
            global_secondary_index: event_store_indexes(component_attrs),
            stream_enabled: component_attrs.event_store.stream_enabled,
            stream_view_type: component_attrs.event_store.stream_enabled ? 'NEW_AND_OLD_IMAGES' : nil,
            ttl: event_store_ttl(component_attrs),
            server_side_encryption: event_store_encryption(component_attrs),
            point_in_time_recovery: { enabled: component_attrs.event_store.point_in_time_recovery },
            tags: component_tag_set
          }.compact)
        end

        def create_cqrs_tables(name, component_attrs, component_tag_set)
          return {} unless component_attrs.cqrs&.enabled

          {
            command_table: create_command_table(name, component_attrs, component_tag_set),
            query_table: create_query_table(name, component_attrs, component_tag_set)
          }
        end

        def create_dead_letter_queue(name, component_attrs, component_tag_set)
          return nil unless component_attrs.dead_letter_queue_enabled

          aws_sqs_queue(component_resource_name(name, :dlq), {
            name: "#{name}-dlq",
            message_retention_seconds: 1_209_600,
            kms_master_key_id: 'alias/aws/sqs',
            tags: component_tag_set
          })
        end

        private

        def event_store_attributes
          [
            { name: 'aggregate_id', type: 'S' },
            { name: 'sequence_number', type: 'N' },
            { name: 'event_type', type: 'S' },
            { name: 'timestamp', type: 'S' }
          ]
        end

        def event_store_indexes(component_attrs)
          [{
            name: 'event-type-index',
            hash_key: 'event_type',
            range_key: 'timestamp',
            projection_type: 'ALL'
          }] + component_attrs.event_store.global_secondary_indexes
        end

        def event_store_ttl(component_attrs)
          return nil unless component_attrs.event_store.ttl_days

          { attribute_name: 'ttl', enabled: true }
        end

        def event_store_encryption(component_attrs)
          return nil unless component_attrs.event_store.encryption_type == 'KMS'

          { enabled: true, kms_key_arn: component_attrs.event_store.kms_key_ref&.arn }
        end

        def create_command_table(name, component_attrs, component_tag_set)
          aws_dynamodb_table(component_resource_name(name, :command_table), {
            name: component_attrs.cqrs.command_table_name,
            billing_mode: 'PAY_PER_REQUEST',
            hash_key: 'command_id',
            range_key: 'timestamp',
            attribute: command_table_attributes,
            global_secondary_index: command_table_indexes,
            server_side_encryption: { enabled: true },
            tags: component_tag_set
          })
        end

        def command_table_attributes
          [
            { name: 'command_id', type: 'S' },
            { name: 'timestamp', type: 'S' },
            { name: 'aggregate_id', type: 'S' },
            { name: 'status', type: 'S' }
          ]
        end

        def command_table_indexes
          [
            { name: 'aggregate-index', hash_key: 'aggregate_id', range_key: 'timestamp', projection_type: 'ALL' },
            { name: 'status-index', hash_key: 'status', range_key: 'timestamp', projection_type: 'ALL' }
          ]
        end

        def create_query_table(name, component_attrs, component_tag_set)
          aws_dynamodb_table(component_resource_name(name, :query_table), {
            name: component_attrs.cqrs.query_table_name,
            billing_mode: 'PAY_PER_REQUEST',
            hash_key: 'id',
            attribute: [
              { name: 'id', type: 'S' },
              { name: 'type', type: 'S' },
              { name: 'updated_at', type: 'S' }
            ],
            global_secondary_index: [
              { name: 'type-index', hash_key: 'type', range_key: 'updated_at', projection_type: 'ALL' }
            ],
            server_side_encryption: { enabled: true },
            tags: component_tag_set
          })
        end
      end
    end
  end
end
