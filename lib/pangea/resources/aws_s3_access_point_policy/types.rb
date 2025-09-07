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
      module S3AccessPointPolicy
        # Common types for S3 Access Point Policy configurations
        class Types < Dry::Types::Module
          include Dry.Types()

          # S3 Access Point ARN constraint
          AccessPointArn = String.constrained(
            format: /\Aarn:aws:s3:[a-z0-9\-]*:[0-9]{12}:accesspoint\/[a-z0-9\-]+\z/
          )
        end

        # S3 Access Point Policy attributes with comprehensive validation
        class S3AccessPointPolicyAttributes < Dry::Struct
          include Types[self]
          
          # Required attributes
          attribute :access_point_arn, AccessPointArn
          attribute :policy, String
          
          # Computed properties
          def policy_document
            JSON.parse(policy) rescue nil
          end
          
          def has_valid_json?
            !policy_document.nil?
          end
          
          def access_point_name
            access_point_arn.split('/')[-1]
          end
          
          def account_id
            access_point_arn.split(':')[4]
          end
          
          def region
            access_point_arn.split(':')[3]
          end
        end
      end
    end
  end
end