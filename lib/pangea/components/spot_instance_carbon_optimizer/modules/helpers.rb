# frozen_string_literal: true
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

module Pangea
  module Components
    module SpotInstanceCarbonOptimizer
      # Shared helper methods for Spot Instance Carbon Optimizer components
      module Helpers
        def get_latest_ami(region, instance_type)
          # Return appropriate AMI based on instance architecture
          if instance_type.include?('g.') # Graviton
            "ami-0123456789abcdef0" # Amazon Linux 2 ARM
          else
            "ami-0987654321fedcba9" # Amazon Linux 2 x86
          end
        end

        def create_security_group(input, region, vpc_id)
          # In practice, this would create or reference an existing security group
          "sg-#{region}-#{vpc_id}-carbon"
        end

        def calculate_spot_price(input, region)
          # Calculate max spot price with buffer
          # In practice, this would query current spot prices
          base_price = 0.10 # Example base price
          buffer = 1 + (input.spot_price_buffer_percentage / 100.0)
          (base_price * buffer).round(4).to_s
        end

        def generate_user_data(input, region)
          <<~BASH
            #!/bin/bash
            # Install CloudWatch agent
            wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
            sudo rpm -U ./amazon-cloudwatch-agent.rpm

            # Configure for carbon monitoring
            cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<EOF
            {
              "metrics": {
                "namespace": "SpotCarbonOptimizer/#{input.name}",
                "metrics_collected": {
                  "cpu": {
                    "measurement": [
                      "cpu_usage_idle",
                      "cpu_usage_iowait"
                    ],
                    "metrics_collection_interval": 60
                  },
                  "disk": {
                    "measurement": [
                      "used_percent"
                    ],
                    "metrics_collection_interval": 60,
                    "resources": [
                      "*"
                    ]
                  },
                  "mem": {
                    "measurement": [
                      "mem_used_percent"
                    ],
                    "metrics_collection_interval": 60
                  }
                }
              }
            }
            EOF

            # Start CloudWatch agent
            sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \\
              -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

            # Tag instance with carbon data
            INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
            REGION=#{region}
            aws ec2 create-tags --region $REGION --resources $INSTANCE_ID \\
              --tags Key=CarbonRegion,Value=$REGION Key=WorkloadType,Value=#{input.workload_type}
          BASH
        end
      end
    end
  end
end
