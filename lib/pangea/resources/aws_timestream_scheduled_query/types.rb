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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsTimestreamScheduledQuery resources
      # Provides a Timestream scheduled query resource.
      class TimestreamScheduledQueryAttributes < Dry::Struct
        attribute :name, Resources::Types::String
        attribute :query_string, Resources::Types::String
        attribute :schedule_configuration, Resources::Types::Hash.default({}.freeze)
        attribute :notification_configuration, Resources::Types::Hash.default({}.freeze)
        attribute :target_configuration, Resources::Types::Hash.default({}.freeze).optional
        attribute :client_token, Resources::Types::String.optional
        attribute :scheduled_query_execution_role_arn, Resources::Types::String
        attribute :error_report_configuration, Resources::Types::Hash.default({}.freeze).optional
        attribute :kms_key_id, Resources::Types::String.optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_timestream_scheduled_query

      end
    end
      end
    end
  end
end