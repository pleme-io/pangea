# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Managed Blockchain Node resources
      class ManagedBlockchainNodeAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Network ID (required)
        attribute :network_id, Resources::Types::String

        # Member ID (required for Hyperledger Fabric)
        attribute? :member_id, Resources::Types::String.optional

        # Node configuration (required)
        attribute :node_configuration, Resources::Types::Hash.schema(
          availability_zone: Resources::Types::String,
          instance_type: Resources::Types::String.enum(
            'bc.t3.small',
            'bc.t3.medium',
            'bc.t3.large',
            'bc.t3.xlarge',
            'bc.m5.large',
            'bc.m5.xlarge',
            'bc.m5.2xlarge',
            'bc.m5.4xlarge',
            'bc.c5.large',
            'bc.c5.xlarge',
            'bc.c5.2xlarge',
            'bc.c5.4xlarge'
          ),
          log_publishing_configuration?: Resources::Types::Hash.schema(
            fabric?: Resources::Types::Hash.schema(
              chaincode_logs?: Resources::Types::Hash.schema(
                cloudwatch?: Resources::Types::Hash.schema(
                  enabled?: Resources::Types::Bool.optional
                ).optional
              ).optional,
              peer_logs?: Resources::Types::Hash.schema(
                cloudwatch?: Resources::Types::Hash.schema(
                  enabled?: Resources::Types::Bool.optional
                ).optional
              ).optional
            ).optional
          ).optional,
          state_db?: Resources::Types::String.enum('LevelDB', 'CouchDB').optional
        )

        # Tags (optional)
        attribute? :tags, Resources::Types::Hash.schema(
          Resources::Types::String => Resources::Types::String
        ).optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate network ID format
          unless attrs.network_id.match?(/\An-[A-Z0-9]{26}\z/)
            raise Dry::Struct::Error, "network_id must be in format 'n-XXXXXXXXXXXXXXXXXXXXXXXXXXXX'"
          end

          # Validate member ID format if provided
          if attrs.member_id && !attrs.member_id.match?(/\Am-[A-Z0-9]{26}\z/)
            raise Dry::Struct::Error, "member_id must be in format 'm-XXXXXXXXXXXXXXXXXXXXXXXXXXXX'"
          end

          # Validate availability zone format
          unless attrs.node_configuration[:availability_zone].match?(/\A[a-z]{2}-[a-z]+-\d[a-z]\z/)
            raise Dry::Struct::Error, "availability_zone must be a valid AWS availability zone (e.g., us-east-1a)"
          end

          # Validate instance type recommendations
          validate_instance_type_for_workload(attrs)

          attrs
        end

        def self.validate_instance_type_for_workload(attrs)
          instance_type = attrs.node_configuration[:instance_type]
          
          # Check if CouchDB is being used with insufficient resources
          if attrs.node_configuration[:state_db] == 'CouchDB'
            small_instances = ['bc.t3.small', 'bc.t3.medium']
            if small_instances.include?(instance_type)
              raise Dry::Struct::Error, "CouchDB requires at least bc.t3.large instance type for adequate performance"
            end
          end
        end

        # Helper methods
        def instance_family
          node_configuration[:instance_type].split('.')[1]
        end

        def instance_size
          node_configuration[:instance_type].split('.')[2]
        end

        def is_burstable?
          instance_family == 't3'
        end

        def is_compute_optimized?
          instance_family == 'c5'
        end

        def is_general_purpose?
          instance_family == 'm5'
        end

        def uses_couchdb?
          node_configuration[:state_db] == 'CouchDB'
        end

        def uses_leveldb?
          node_configuration[:state_db] == 'LevelDB' || node_configuration[:state_db].nil?
        end

        def chaincode_logging_enabled?
          node_configuration.dig(:log_publishing_configuration, :fabric, :chaincode_logs, :cloudwatch, :enabled) || false
        end

        def peer_logging_enabled?
          node_configuration.dig(:log_publishing_configuration, :fabric, :peer_logs, :cloudwatch, :enabled) || false
        end

        def any_logging_enabled?
          chaincode_logging_enabled? || peer_logging_enabled?
        end

        def estimated_monthly_cost
          # Base hourly costs by instance type
          hourly_costs = {
            'bc.t3.small' => 0.078,
            'bc.t3.medium' => 0.156,
            'bc.t3.large' => 0.312,
            'bc.t3.xlarge' => 0.624,
            'bc.m5.large' => 0.354,
            'bc.m5.xlarge' => 0.708,
            'bc.m5.2xlarge' => 1.416,
            'bc.m5.4xlarge' => 2.832,
            'bc.c5.large' => 0.306,
            'bc.c5.xlarge' => 0.612,
            'bc.c5.2xlarge' => 1.224,
            'bc.c5.4xlarge' => 2.448
          }

          base_hourly = hourly_costs[node_configuration[:instance_type]] || 0
          
          # Add 10% for CouchDB overhead
          if uses_couchdb?
            base_hourly *= 1.1
          end

          # Add cost for CloudWatch logging
          if any_logging_enabled?
            base_hourly += 0.02 # Approximate logging cost
          end

          # Convert to monthly (730 hours)
          base_hourly * 730
        end

        def recommended_specs
          specs = case node_configuration[:instance_type]
          when 'bc.t3.small'
            { vcpu: 2, memory_gib: 2, network: 'Up to 5 Gbps' }
          when 'bc.t3.medium'
            { vcpu: 2, memory_gib: 4, network: 'Up to 5 Gbps' }
          when 'bc.t3.large'
            { vcpu: 2, memory_gib: 8, network: 'Up to 5 Gbps' }
          when 'bc.t3.xlarge'
            { vcpu: 4, memory_gib: 16, network: 'Up to 5 Gbps' }
          when 'bc.m5.large'
            { vcpu: 2, memory_gib: 8, network: 'Up to 10 Gbps' }
          when 'bc.m5.xlarge'
            { vcpu: 4, memory_gib: 16, network: 'Up to 10 Gbps' }
          when 'bc.m5.2xlarge'
            { vcpu: 8, memory_gib: 32, network: 'Up to 10 Gbps' }
          when 'bc.m5.4xlarge'
            { vcpu: 16, memory_gib: 64, network: 'Up to 10 Gbps' }
          when 'bc.c5.large'
            { vcpu: 2, memory_gib: 4, network: 'Up to 10 Gbps' }
          when 'bc.c5.xlarge'
            { vcpu: 4, memory_gib: 8, network: 'Up to 10 Gbps' }
          when 'bc.c5.2xlarge'
            { vcpu: 8, memory_gib: 16, network: 'Up to 10 Gbps' }
          when 'bc.c5.4xlarge'
            { vcpu: 16, memory_gib: 32, network: 'Up to 10 Gbps' }
          else
            { vcpu: 0, memory_gib: 0, network: 'Unknown' }
          end

          specs.merge(state_db: node_configuration[:state_db] || 'LevelDB')
        end

        def performance_tier
          case instance_size
          when 'small', 'medium'
            :development
          when 'large'
            :standard
          when 'xlarge'
            :performance
          when '2xlarge', '4xlarge'
            :high_performance
          else
            :unknown
          end
        end

        def max_chaincode_connections
          # Estimate based on instance size
          case performance_tier
          when :development
            50
          when :standard
            200
          when :performance
            500
          when :high_performance
            1000
          else
            0
          end
        end
      end
    end
      end
    end
  end
end