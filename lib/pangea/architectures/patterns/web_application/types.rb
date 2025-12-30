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

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Architectures
    module Patterns
      module WebApplication
        # Web application architecture attributes with validation
        class Attributes < Dry::Struct
          transform_keys(&:to_sym)

          # Core configuration
          attribute :domain, Types::String
          attribute :environment, Types::String.default('development').enum('development', 'staging', 'production')
          attribute :vpc_cidr, Types::String.default('10.0.0.0/16')
          attribute :availability_zones, Types::Array.of(Types::String).default(%w[us-east-1a us-east-1b].freeze)

          # Scaling and availability
          attribute :high_availability, Types::Bool.default(false)
          attribute :auto_scaling, Types::Hash.schema(
            min?: Types::Integer.default(1),
            max?: Types::Integer.default(5),
            desired?: Types::Integer.default(2)
          ).default({}.freeze)

          # Instance configuration
          attribute :instance_type, Types::String.default('t3.micro')
          attribute :ami_id, Types::String.default('ami-0c55b159cbfafe1f0')
          attribute? :key_pair, Types::String

          # Database configuration
          attribute :database_enabled, Types::Bool.default(true)
          attribute :database_engine, Types::String.default('postgres').enum('mysql', 'postgres')
          attribute :database_instance_class, Types::String.default('db.t3.micro')
          attribute :database_allocated_storage, Types::Integer.default(20)
          attribute :database_backup_retention, Types::Integer.default(7)

          # Storage configuration
          attribute :s3_bucket_enabled, Types::Bool.default(true)
          attribute :cloudfront_enabled, Types::Bool.default(false)

          # Security configuration
          attribute :waf_enabled, Types::Bool.default(false)
          attribute? :ssl_certificate_arn, Types::String

          # Monitoring configuration
          attribute :monitoring_enabled, Types::Bool.default(true)
          attribute :log_retention_days, Types::Integer.default(30)

          # Additional tags
          attribute :tags, Types::Hash.default({}.freeze)

          # Validate configuration compatibility
          def self.new(attributes)
            attrs = super

            if attrs.high_availability && attrs.availability_zones.count < 2
              raise Dry::Struct::Error, 'High availability requires at least 2 availability zones'
            end

            if attrs.environment == 'production' && attrs.auto_scaling[:max] > 1 && !attrs.high_availability
              raise Dry::Struct::Error, 'Auto scaling in production requires high_availability: true'
            end

            attrs
          end

          def production?
            environment == 'production'
          end

          def requires_https?
            production? || ssl_certificate_arn
          end

          def subnet_count
            availability_zones.count * 2
          end
        end
      end
    end
  end
end
