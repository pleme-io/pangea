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
      # Type-safe attributes for AwsTimestreamBatchLoadTask resources
      # Provides a Timestream batch load task resource.
      class TimestreamBatchLoadTaskAttributes < Dry::Struct
        attribute :database_name, Resources::Types::String
        attribute :table_name, Resources::Types::String
        attribute :data_source_configuration, Resources::Types::Hash.default({}.freeze)
        attribute :data_model_configuration, Resources::Types::Hash.default({}.freeze).optional
        attribute :report_configuration, Resources::Types::Hash.default({}.freeze).optional
        attribute :target_database_name, Resources::Types::String.optional
        attribute :target_table_name, Resources::Types::String.optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_timestream_batch_load_task

      end
    end
      end
    end
  end
end