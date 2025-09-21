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

module Pangea
  module Resources
    module AWS
      module S3AccessPoint
        # Common types for S3 Access Point configurations
        class Types < Dry::Types::Module
          include Dry.Types()

          # S3 Access Point Account Owner ID constraint
          AccessPointAccountId = String.constrained(format: /\A\d{12}\z/)
          
          # S3 Access Point Name constraint  
          AccessPointName = String.constrained(min_size: 3, max_size: 63, format: /\A[a-z0-9\-]+\z/)
          
          # S3 Access Point Network Origin
          NetworkOrigin = String.enum('Internet', 'VPC')
          
          # VPC Configuration for Access Point
          VpcConfiguration = Hash.schema({
            vpc_id: String
          })
          
          # Public Access Block Configuration
          PublicAccessBlockConfiguration = Hash.schema({
            block_public_acls?: Bool,
            block_public_policy?: Bool,
            ignore_public_acls?: Bool,
            restrict_public_buckets?: Bool
          })
        end

        # S3 Access Point attributes with comprehensive validation
        class S3AccessPointAttributes < Dry::Struct
          include Types[self]
          
          # Required attributes
          attribute :account_id, AccessPointAccountId
          attribute :bucket, String
          attribute :name, AccessPointName
          
          # Optional attributes
          attribute? :bucket_account_id, AccessPointAccountId
          attribute? :network_origin, NetworkOrigin.default('Internet')
          attribute? :policy, String.optional
          attribute? :vpc_configuration, VpcConfiguration.optional
          attribute? :public_access_block_configuration, PublicAccessBlockConfiguration.default({}.freeze)
          
          # Computed properties
          def vpc_access_point?
            network_origin == 'VPC'
          end
          
          def internet_access_point?
            network_origin == 'Internet'
          end
          
          def has_public_access_block?
            public_access_block_configuration.any?
          end
          
          def cross_account_access?
            bucket_account_id && bucket_account_id != account_id
          end
        end
      end
    end
  end
end