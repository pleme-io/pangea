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
      module Types
        # Validation methods for web application configuration
        module Validation
          module_function

          def validate_web_application_config(attributes)
            validate_auto_scaling(attributes[:auto_scaling])
            validate_availability_zones(attributes[:region], attributes[:availability_zones])
            validate_database_storage(attributes) if attributes[:database_enabled]
            validate_ssl_certificate_arn(attributes[:ssl_certificate_arn])
            validate_vpc_cidr(attributes[:vpc_cidr])

            true
          end

          def validate_auto_scaling(auto_scaling)
            return unless auto_scaling && auto_scaling[:desired]

            unless auto_scaling[:min] <= auto_scaling[:desired] && auto_scaling[:desired] <= auto_scaling[:max]
              raise ArgumentError, 'Auto scaling desired capacity must be between min and max'
            end
          end

          def validate_availability_zones(region, availability_zones)
            return unless region && availability_zones

            unless availability_zones.all? { |az| az.start_with?(region) }
              raise ArgumentError, "All availability zones must be in the specified region: #{region}"
            end
          end

          def validate_database_storage(attributes)
            storage = attributes[:database_allocated_storage]
            engine = attributes[:database_engine]

            case engine
            when 'aurora', 'aurora-mysql', 'aurora-postgresql'
              raise ArgumentError, 'Aurora minimum storage is 10 GB' if storage < 10
            else
              raise ArgumentError, 'RDS minimum storage is 20 GB' if storage < 20
            end
          end

          def validate_ssl_certificate_arn(ssl_arn)
            return unless ssl_arn

            unless ssl_arn.match?(%r{^arn:aws:acm:[a-z0-9-]+:\d+:certificate/[a-f0-9-]+$})
              raise ArgumentError, 'Invalid SSL certificate ARN format'
            end
          end

          def validate_vpc_cidr(vpc_cidr)
            return unless vpc_cidr

            unless Pangea::Architectures::Types.validate_cidr_block(vpc_cidr)
              raise ArgumentError, "Invalid VPC CIDR block: #{vpc_cidr}"
            end
          end
        end
      end
    end
  end
end
