# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# lib/pangea/utilities/cost/resource_pricing.rb
module Pangea
  module Utilities
    module Cost
      class ResourcePricing
        # Simplified pricing data - in production, this would come from AWS Pricing API
        PRICING_DATA = {
          'aws_instance' => {
            't3.micro' => { hourly: 0.0104, monthly: 7.59 },
            't3.small' => { hourly: 0.0208, monthly: 15.18 },
            't3.medium' => { hourly: 0.0416, monthly: 30.37 },
            't3.large' => { hourly: 0.0832, monthly: 60.74 },
            'm5.large' => { hourly: 0.096, monthly: 70.08 },
            'm5.xlarge' => { hourly: 0.192, monthly: 140.16 },
            'm5.2xlarge' => { hourly: 0.384, monthly: 280.32 }
          },
          'aws_db_instance' => {
            'db.t3.micro' => { hourly: 0.017, monthly: 12.41 },
            'db.t3.small' => { hourly: 0.034, monthly: 24.82 },
            'db.t3.medium' => { hourly: 0.068, monthly: 49.64 },
            'db.m5.large' => { hourly: 0.171, monthly: 124.83 },
            'db.m5.xlarge' => { hourly: 0.342, monthly: 249.66 }
          },
          'aws_lb' => {
            'application' => { hourly: 0.0225, monthly: 16.43 },
            'network' => { hourly: 0.0225, monthly: 16.43 }
          },
          'aws_nat_gateway' => {
            'default' => { hourly: 0.045, monthly: 32.85 }
          },
          'aws_elasticache_cluster' => {
            'cache.t3.micro' => { hourly: 0.017, monthly: 12.41 },
            'cache.t3.small' => { hourly: 0.034, monthly: 24.82 },
            'cache.t3.medium' => { hourly: 0.068, monthly: 49.64 }
          }
        }.freeze
        
        def self.get_price(resource_type, resource_spec)
          return { hourly: 0, monthly: 0 } unless PRICING_DATA[resource_type]
          
          case resource_type
          when 'aws_instance'
            instance_type = resource_spec[:instance_type] || resource_spec['instance_type']
            PRICING_DATA[resource_type][instance_type] || { hourly: 0, monthly: 0 }
          when 'aws_db_instance'
            instance_class = resource_spec[:instance_class] || resource_spec['instance_class']
            PRICING_DATA[resource_type][instance_class] || { hourly: 0, monthly: 0 }
          when 'aws_lb'
            lb_type = resource_spec[:load_balancer_type] || resource_spec['load_balancer_type'] || 'application'
            PRICING_DATA[resource_type][lb_type] || { hourly: 0, monthly: 0 }
          when 'aws_elasticache_cluster'
            node_type = resource_spec[:node_type] || resource_spec['node_type']
            PRICING_DATA[resource_type][node_type] || { hourly: 0, monthly: 0 }
          else
            PRICING_DATA[resource_type]&.fetch('default', { hourly: 0, monthly: 0 }) || { hourly: 0, monthly: 0 }
          end
        end
        
        def self.estimate_data_transfer_cost(gb_per_month)
          # Simplified data transfer pricing
          if gb_per_month <= 1
            0
          elsif gb_per_month <= 10_000
            (gb_per_month - 1) * 0.09
          else
            (9_999 * 0.09) + ((gb_per_month - 10_000) * 0.085)
          end
        end
        
        def self.estimate_storage_cost(storage_type, gb)
          storage_pricing = {
            'gp3' => 0.08,      # per GB-month
            'gp2' => 0.10,      # per GB-month
            'io1' => 0.125,     # per GB-month
            'st1' => 0.045,     # per GB-month
            'sc1' => 0.025,     # per GB-month
            's3_standard' => 0.023,  # per GB-month
            's3_ia' => 0.0125,       # per GB-month
            's3_glacier' => 0.004    # per GB-month
          }
          
          price_per_gb = storage_pricing[storage_type] || 0.10
          gb * price_per_gb
        end
      end
    end
  end
end