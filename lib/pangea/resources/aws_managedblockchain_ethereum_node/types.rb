# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Managed Blockchain Ethereum Node resources
      class ManagedBlockchainEthereumNodeAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Network ID (required)
        attribute :network_id, Resources::Types::String.enum(
          'n-ethereum-mainnet',
          'n-ethereum-goerli',
          'n-ethereum-rinkeby'
        )

        # Node configuration (required)
        attribute :node_configuration, Resources::Types::Hash.schema(
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
            'bc.c5.4xlarge',
            'bc.r5.large',
            'bc.r5.xlarge',
            'bc.r5.2xlarge',
            'bc.r5.4xlarge'
          ),
          availability_zone?: Resources::Types::String.optional,
          subnet_id?: Resources::Types::String.optional
        )

        # Client request token (optional)
        attribute? :client_request_token, Resources::Types::String.optional

        # Tags (optional)
        attribute? :tags, Resources::Types::Hash.schema(
          Resources::Types::String => Resources::Types::String
        ).optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate availability zone format if provided
          if attrs.node_configuration[:availability_zone]
            az = attrs.node_configuration[:availability_zone]
            unless az.match?(/\A[a-z0-9\-]+[a-z]\z/)
              raise Dry::Struct::Error, "availability_zone must be a valid AWS availability zone format"
            end
          end

          # Validate subnet ID format if provided
          if attrs.node_configuration[:subnet_id]
            subnet_id = attrs.node_configuration[:subnet_id]
            unless subnet_id.match?(/\Asubnet-[a-f0-9]{8,17}\z/)
              raise Dry::Struct::Error, "subnet_id must be a valid AWS subnet ID format"
            end
          end

          # Validate client request token format if provided
          if attrs.client_request_token
            unless attrs.client_request_token.match?(/\A[a-zA-Z0-9\-_]{1,64}\z/)
              raise Dry::Struct::Error, "client_request_token must be 1-64 characters long and contain only alphanumeric characters, hyphens, and underscores"
            end
          end

          # Validate instance type suitability for network
          instance_type = attrs.node_configuration[:instance_type]
          if attrs.network_id == 'n-ethereum-mainnet'
            # Mainnet requires more robust instances
            if instance_type.start_with?('bc.t3.small', 'bc.t3.medium')
              raise Dry::Struct::Error, "Ethereum mainnet requires at least bc.t3.large instance type"
            end
          end

          attrs
        end

        # Helper methods
        def is_mainnet_node?
          network_id == 'n-ethereum-mainnet'
        end

        def is_testnet_node?
          network_id != 'n-ethereum-mainnet'
        end

        def instance_family
          # Extract family from instance type: bc.t3.large -> t3
          instance_type = node_configuration[:instance_type]
          parts = instance_type.split('.')
          return 'unknown' if parts.length < 2
          parts[1]
        end

        def instance_size
          # Extract size from instance type: bc.t3.large -> large
          instance_type = node_configuration[:instance_type]
          parts = instance_type.split('.')
          return 'unknown' if parts.length < 3
          parts[2]
        end

        def estimated_monthly_cost
          # Rough cost estimates per instance type (USD per month)
          instance_costs = {
            'bc.t3.small' => 29.20,
            'bc.t3.medium' => 58.40,
            'bc.t3.large' => 116.80,
            'bc.t3.xlarge' => 233.60,
            'bc.m5.large' => 182.50,
            'bc.m5.xlarge' => 365.00,
            'bc.m5.2xlarge' => 730.00,
            'bc.m5.4xlarge' => 1460.00,
            'bc.c5.large' => 163.84,
            'bc.c5.xlarge' => 327.68,
            'bc.c5.2xlarge' => 655.36,
            'bc.c5.4xlarge' => 1310.72,
            'bc.r5.large' => 240.44,
            'bc.r5.xlarge' => 480.88,
            'bc.r5.2xlarge' => 961.76,
            'bc.r5.4xlarge' => 1923.52
          }

          base_cost = instance_costs[node_configuration[:instance_type]] || 200.0

          # Add premium for mainnet
          mainnet_multiplier = is_mainnet_node? ? 1.5 : 1.0

          base_cost * mainnet_multiplier
        end

        def storage_capacity_gb
          # Estimated storage capacity based on instance type
          case instance_family
          when 't3'
            case instance_size
            when 'small'
              250
            when 'medium'
              500
            when 'large', 'xlarge'
              1000
            else
              500
            end
          when 'm5'
            case instance_size
            when 'large'
              1000
            when 'xlarge'
              2000
            when '2xlarge'
              4000
            when '4xlarge'
              8000
            else
              2000
            end
          when 'c5'
            case instance_size
            when 'large'
              750
            when 'xlarge'
              1500
            when '2xlarge'
              3000
            when '4xlarge'
              6000
            else
              1500
            end
          when 'r5'
            case instance_size
            when 'large'
              1500
            when 'xlarge'
              3000
            when '2xlarge'
              6000
            when '4xlarge'
              12000
            else
              3000
            end
          else
            1000
          end
        end

        def network_throughput_mbps
          # Network performance based on instance family
          case instance_family
          when 't3'
            case instance_size
            when 'small'
              100
            when 'medium'
              250
            when 'large'
              500
            when 'xlarge'
              1000
            else
              250
            end
          when 'm5', 'c5', 'r5'
            case instance_size
            when 'large'
              750
            when 'xlarge'
              1250
            when '2xlarge'
              2500
            when '4xlarge'
              5000
            else
              1250
            end
          else
            500
          end
        end

        def supports_archival_data?
          # Larger instances support archival data
          storage_capacity_gb >= 2000
        end

        def is_high_availability?
          # Subnet ID indicates VPC deployment for HA
          !node_configuration[:subnet_id].nil?
        end

        def blockchain_protocol
          'ethereum'
        end

        def network_name
          case network_id
          when 'n-ethereum-mainnet'
            'mainnet'
          when 'n-ethereum-goerli'
            'goerli'
          when 'n-ethereum-rinkeby'
            'rinkeby'
          else
            'unknown'
          end
        end

        def is_burstable_instance?
          instance_family == 't3'
        end

        def is_compute_optimized?
          instance_family == 'c5'
        end

        def is_memory_optimized?
          instance_family == 'r5'
        end

        def is_general_purpose?
          ['m5', 't3'].include?(instance_family)
        end

        # Get synchronization mode
        def sync_mode
          if is_mainnet_node? && storage_capacity_gb >= 4000
            'full' # Full node with complete blockchain data
          elsif storage_capacity_gb >= 1000
            'fast' # Fast sync mode
          else
            'light' # Light client mode
          end
        end

        # Calculate performance score
        def performance_score
          score = 0
          
          # Base score by instance family
          case instance_family
          when 't3'
            score += 50 # Burstable, good for light workloads
          when 'm5'
            score += 80 # Balanced, good for general use
          when 'c5'
            score += 90 # Compute optimized, excellent for sync
          when 'r5'
            score += 85 # Memory optimized, good for large state
          end
          
          # Size bonus
          case instance_size
          when 'small'
            score += 0
          when 'medium'
            score += 10
          when 'large'
            score += 20
          when 'xlarge'
            score += 30
          when '2xlarge'
            score += 40
          when '4xlarge'
            score += 50
          end
          
          # Network bonus
          score += 10 if is_high_availability?
          score += 5 if supports_archival_data?
          
          [score, 0].max
        end
      end
    end
      end
    end
  end
end