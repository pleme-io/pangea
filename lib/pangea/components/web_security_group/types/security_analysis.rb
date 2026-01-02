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
    module WebSecurityGroup
      module Types
        # Security analysis methods for WebSecurityGroupAttributes
        module SecurityAnalysis
          def security_risk_level
            risks = []
            risks << 'SSH_OPEN_INTERNET' if enable_ssh && ssh_cidr_blocks.include?("0.0.0.0/0")
            risks << 'HTTP_ONLY' if enable_http && !enable_https
            risks << 'WIDE_OPEN_ACCESS' if allowed_cidr_blocks.include?("0.0.0.0/0")
            risks << 'PING_ENABLED' if enable_ping

            case risks.length
            when 0 then 'low'
            when 1..2 then 'medium'
            when 3.. then 'high'
            end
          end

          def security_recommendations
            recommendations = []

            if enable_ssh && ssh_cidr_blocks.include?("0.0.0.0/0")
              recommendations << "Restrict SSH access to specific IP ranges or use a bastion host"
            end

            if enable_http && !enable_https
              recommendations << "Enable HTTPS and consider redirecting HTTP to HTTPS"
            end

            if allowed_cidr_blocks.include?("0.0.0.0/0") && security_profile == 'strict'
              recommendations << "Consider restricting web access to specific IP ranges or CloudFront"
            end

            if !enable_outbound_internet
              recommendations << "Ensure instances can reach required external services"
            end

            recommendations
          end

          def compliance_profile
            features = []
            features << 'HTTPS_ENABLED' if enable_https
            features << 'SSH_RESTRICTED' if enable_ssh && !ssh_cidr_blocks.include?("0.0.0.0/0")
            features << 'OUTBOUND_CONTROLLED' if !enable_outbound_internet
            features << 'VPC_ISOLATION' if enable_vpc_communication && !allowed_cidr_blocks.include?("0.0.0.0/0")
            features << 'NO_PING' if !enable_ping

            {
              level: case features.length
                     when 0..1 then 'basic'
                     when 2..3 then 'standard'
                     when 4..5 then 'strict'
                     end,
              features: features
            }
          end
        end
      end
    end
  end
end
