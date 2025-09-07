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


require 'pangea/resources/base'
require 'pangea/resources/aws_sagemaker_feature_group/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # SageMaker Feature Group resource for ML feature management
      class SageMakerFeatureGroup < Base
        def self.resource_type
          'aws_sagemaker_feature_group'
        end
        
        def self.attribute_struct
          Types::SageMakerFeatureGroupAttributes
        end
      end
      
      def aws_sagemaker_feature_group(name, attributes)
        resource = SageMakerFeatureGroup.new(
          name: name,
          attributes: attributes
        )
        
        add_resource(resource)
        
        ResourceReference.new(
          name: name,
          type: :aws_sagemaker_feature_group,
          attributes: {
            id: "${aws_sagemaker_feature_group.#{name}.id}",
            arn: "${aws_sagemaker_feature_group.#{name}.arn}",
            feature_group_name: "${aws_sagemaker_feature_group.#{name}.feature_group_name}",
            feature_group_status: "${aws_sagemaker_feature_group.#{name}.feature_group_status}",
            has_online_store: attributes.dig(:online_store_config, :enable_online_store) != false,
            has_offline_store: !attributes[:offline_store_config].nil?,
            feature_count: attributes[:feature_definitions]&.size || 0,
            uses_ttl: !attributes.dig(:online_store_config, :ttl_duration).nil?,
            table_format: attributes.dig(:offline_store_config, :table_format) || 'Glue'
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)