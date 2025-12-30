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
  module Architectures
    module WebApplicationArchitecture
      class Architecture
        # Resource creation methods (both direct and fallback)
        module ResourceCreation
          def create_resources(name, attributes, _components)
            resources = {}
            resources[:dns_zone] = create_dns_zone(name, attributes) if attributes[:domain_name]
            resources[:ssl_certificate] = create_ssl_certificate(name, attributes) if attributes[:domain_name] && !attributes[:ssl_certificate_arn]
            resources[:s3_buckets] = create_s3_buckets(name, attributes)
            resources
          end

          def create_dns_zone(_name, _attributes)
            { zone_id: 'Z1234567890123', name_servers: %w[ns-123.awsdns-12.com ns-456.awsdns-45.net] }
          end

          def create_ssl_certificate(_name, attributes)
            { certificate_arn: 'arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012', domain_name: attributes[:domain_name] }
          end

          def create_s3_buckets(name, _attributes)
            { logs_bucket: { name: "#{name}-logs-#{SecureRandom.hex(8)}" }, assets_bucket: { name: "#{name}-assets-#{SecureRandom.hex(8)}" } }
          end

          def create_cloudwatch_alarms(name, _attributes, _components)
            { high_cpu_alarm: "#{name}-high-cpu", low_cpu_alarm: "#{name}-low-cpu", target_response_time_alarm: "#{name}-response-time" }
          end

          def create_cloudwatch_dashboard(name, _attributes, _components)
            { dashboard_name: "#{name}-dashboard", url: "https://console.aws.amazon.com/cloudwatch/home#dashboards:name=#{name}-dashboard" }
          end
        end
      end
    end
  end
end
