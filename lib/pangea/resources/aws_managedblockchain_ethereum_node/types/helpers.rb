# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        class ManagedBlockchainEthereumNodeAttributes
          INSTANCE_COSTS = {
            'bc.t3.small' => 29.20, 'bc.t3.medium' => 58.40,
            'bc.t3.large' => 116.80, 'bc.t3.xlarge' => 233.60,
            'bc.m5.large' => 182.50, 'bc.m5.xlarge' => 365.00,
            'bc.m5.2xlarge' => 730.00, 'bc.m5.4xlarge' => 1460.00,
            'bc.c5.large' => 163.84, 'bc.c5.xlarge' => 327.68,
            'bc.c5.2xlarge' => 655.36, 'bc.c5.4xlarge' => 1310.72,
            'bc.r5.large' => 240.44, 'bc.r5.xlarge' => 480.88,
            'bc.r5.2xlarge' => 961.76, 'bc.r5.4xlarge' => 1923.52
          }.freeze

          def is_mainnet_node? = network_id == 'n-ethereum-mainnet'
          def is_testnet_node? = !is_mainnet_node?
          def blockchain_protocol = 'ethereum'
          def is_burstable_instance? = instance_family == 't3'
          def is_compute_optimized? = instance_family == 'c5'
          def is_memory_optimized? = instance_family == 'r5'
          def is_general_purpose? = ['m5', 't3'].include?(instance_family)
          def supports_archival_data? = storage_capacity_gb >= 2000
          def is_high_availability? = !node_configuration[:subnet_id].nil?

          def instance_family
            parts = node_configuration[:instance_type].split('.')
            parts.length >= 2 ? parts[1] : 'unknown'
          end

          def instance_size
            parts = node_configuration[:instance_type].split('.')
            parts.length >= 3 ? parts[2] : 'unknown'
          end

          def network_name
            { 'n-ethereum-mainnet' => 'mainnet',
              'n-ethereum-goerli' => 'goerli',
              'n-ethereum-rinkeby' => 'rinkeby' }[network_id] || 'unknown'
          end

          def estimated_monthly_cost
            base = INSTANCE_COSTS[node_configuration[:instance_type]] || 200.0
            base * (is_mainnet_node? ? 1.5 : 1.0)
          end

          def storage_capacity_gb
            storage_by_family[instance_family]&.[](instance_size) ||
              storage_by_family[instance_family]&.values&.first || 1000
          end

          def network_throughput_mbps
            throughput_by_family[instance_family]&.[](instance_size) ||
              throughput_by_family[instance_family]&.values&.first || 500
          end

          def sync_mode
            return 'full' if is_mainnet_node? && storage_capacity_gb >= 4000
            storage_capacity_gb >= 1000 ? 'fast' : 'light'
          end

          def performance_score
            score = family_scores[instance_family] || 50
            score += size_scores[instance_size] || 0
            score += 10 if is_high_availability?
            score += 5 if supports_archival_data?
            [score, 0].max
          end

          private

          def storage_by_family
            { 't3' => { 'small' => 250, 'medium' => 500, 'large' => 1000, 'xlarge' => 1000 },
              'm5' => { 'large' => 1000, 'xlarge' => 2000, '2xlarge' => 4000, '4xlarge' => 8000 },
              'c5' => { 'large' => 750, 'xlarge' => 1500, '2xlarge' => 3000, '4xlarge' => 6000 },
              'r5' => { 'large' => 1500, 'xlarge' => 3000, '2xlarge' => 6000, '4xlarge' => 12000 } }
          end

          def throughput_by_family
            { 't3' => { 'small' => 100, 'medium' => 250, 'large' => 500, 'xlarge' => 1000 },
              'm5' => { 'large' => 750, 'xlarge' => 1250, '2xlarge' => 2500, '4xlarge' => 5000 },
              'c5' => { 'large' => 750, 'xlarge' => 1250, '2xlarge' => 2500, '4xlarge' => 5000 },
              'r5' => { 'large' => 750, 'xlarge' => 1250, '2xlarge' => 2500, '4xlarge' => 5000 } }
          end

          def family_scores = { 't3' => 50, 'm5' => 80, 'c5' => 90, 'r5' => 85 }
          def size_scores = { 'small' => 0, 'medium' => 10, 'large' => 20, 'xlarge' => 30, '2xlarge' => 40, '4xlarge' => 50 }
        end
      end
    end
  end
end
