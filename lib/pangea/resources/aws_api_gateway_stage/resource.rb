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
require_relative 'types'
require_relative 'resource/main'
require_relative 'resource/helpers'

module Pangea
  module Resources
    module AWS
      # AWS API Gateway Stage implementation
      # Provides type-safe function for creating API stages
      def aws_api_gateway_stage(name, attributes = {})
        extend ApiGatewayStageResource::Main
        extend ApiGatewayStageResource::Helpers

        # Validate attributes using dry-struct
        stage_attrs = Types::Types::ApiGatewayStageAttributes.new(attributes)

        # Generate the Terraform resource
        generate_stage_resource(name, stage_attrs)

        # Create ResourceReference with outputs and computed properties
        ref = create_stage_reference(name, stage_attrs)

        # Add computed properties via method delegation
        add_reference_helpers(ref, name, stage_attrs)

        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)
