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
require 'pangea/resources/reference'
require 'pangea/resources/aws_mq_configuration/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS MQ Configuration
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] MQ configuration attributes
      # @option attributes [String] :name The configuration name
      # @option attributes [String] :engine_type ActiveMQ or RabbitMQ
      # @option attributes [String] :engine_version Engine version
      # @option attributes [String] :data Configuration data (XML for ActiveMQ, Erlang/JSON for RabbitMQ)
      # @option attributes [String] :authentication_strategy Authentication strategy
      # @option attributes [String] :description Configuration description
      # @option attributes [Hash] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_mq_configuration(name, attributes = {})
        # Validate attributes using dry-struct
        config_attrs = Types::Types::MqConfigurationAttributes.new(attributes)
        
        # Generate terraform resource block
        resource(:aws_mq_configuration, name) do
          name config_attrs.name
          engine_type config_attrs.engine_type
          engine_version config_attrs.engine_version
          data config_attrs.data
          
          authentication_strategy config_attrs.authentication_strategy if config_attrs.authentication_strategy != 'simple'
          description config_attrs.description if config_attrs.description
          
          # Tags
          if config_attrs.tags&.any?
            tags config_attrs.tags
          end
        end
        
        # Return resource reference with outputs
        ResourceReference.new(
          type: 'aws_mq_configuration',
          name: name,
          resource_attributes: config_attrs.to_h,
          outputs: {
            id: "${aws_mq_configuration.#{name}.id}",
            arn: "${aws_mq_configuration.#{name}.arn}",
            name: "${aws_mq_configuration.#{name}.name}",
            latest_revision: "${aws_mq_configuration.#{name}.latest_revision}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)