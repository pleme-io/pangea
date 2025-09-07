# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'
require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module ElastiCacheExtended
        # ElastiCache global replication group for cross-region replication
        class GlobalReplicationGroupAttributes < Dry::Struct
          attribute :global_replication_group_id_suffix, Types::String
          attribute :primary_replication_group_id, Types::String
          attribute :global_replication_group_description, Types::String.optional
          attribute :cache_node_type, Types::String.optional
          attribute :engine_version, Types::String.optional
          attribute :num_node_groups, Types::Integer.optional
          attribute :parameter_group_name, Types::String.optional
          
          attribute? :automatic_failover_enabled, Types::Bool.default(true)
          attribute? :multi_az_enabled, Types::Bool.default(true)
        end

        # ElastiCache global replication group reference
        class GlobalReplicationGroupReference < ::Pangea::Resources::ResourceReference
          property :id
          property :global_replication_group_id
          property :arn
          property :engine
          property :status
          property :at_rest_encryption_enabled
          property :auth_token_enabled
          property :cluster_enabled

          def primary_replication_group_id
            get_attribute(:primary_replication_group_id)
          end

          def available?
            status == 'available'
          end

          def creating?
            status == 'creating'
          end

          def modifying?
            status == 'modifying'
          end

          def failover_enabled?
            get_attribute(:automatic_failover_enabled) || false
          end

          def multi_az_enabled?
            get_attribute(:multi_az_enabled) || false
          end

          def encryption_at_rest_enabled?
            at_rest_encryption_enabled || false
          end

          def auth_enabled?
            auth_token_enabled || false
          end

          def redis_cluster_mode?
            cluster_enabled || false
          end

          # Helper for cross-region disaster recovery
          def disaster_recovery_ready?
            available? && failover_enabled? && multi_az_enabled?
          end
        end

        module GlobalReplicationGroup
          # Creates a global replication group for cross-region Redis replication
          #
          # @param name [Symbol] The global replication group name
          # @param attributes [Hash] Global replication group configuration
          # @return [GlobalReplicationGroupReference] Reference to the global replication group
          def aws_elasticache_global_replication_group(name, attributes = {})
            global_attrs = GlobalReplicationGroupAttributes.new(attributes)
            
            synthesizer.resource :aws_elasticache_global_replication_group, name do
              global_replication_group_id_suffix global_attrs.global_replication_group_id_suffix
              primary_replication_group_id global_attrs.primary_replication_group_id
              global_replication_group_description global_attrs.global_replication_group_description if global_attrs.global_replication_group_description
              cache_node_type global_attrs.cache_node_type if global_attrs.cache_node_type
              engine_version global_attrs.engine_version if global_attrs.engine_version
              num_node_groups global_attrs.num_node_groups if global_attrs.num_node_groups
              parameter_group_name global_attrs.parameter_group_name if global_attrs.parameter_group_name
              
              automatic_failover_enabled global_attrs.automatic_failover_enabled
              multi_az_enabled global_attrs.multi_az_enabled
            end

            GlobalReplicationGroupReference.new(name, :aws_elasticache_global_replication_group, synthesizer, global_attrs)
          end
        end
      end
    end
  end
end