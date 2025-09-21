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
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS CodeDeploy Application resources
      class CodeDeployApplicationAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Application name (required)
        attribute :application_name, Resources::Types::String.constrained(
          format: /\A[a-zA-Z0-9._-]+\z/,
          min_size: 1,
          max_size: 100
        )

        # Compute platform (EC2/Server, Lambda, or ECS)
        attribute :compute_platform, Resources::Types::String.enum('Server', 'Lambda', 'ECS').default('Server')

        # Tags
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate application name doesn't contain spaces
          if attrs.application_name.include?(' ')
            raise Dry::Struct::Error, "Application name cannot contain spaces"
          end

          attrs
        end

        # Helper methods
        def ec2_platform?
          compute_platform == 'Server'
        end

        def lambda_platform?
          compute_platform == 'Lambda'
        end

        def ecs_platform?
          compute_platform == 'ECS'
        end

        def supports_deployment_groups?
          # All platforms support deployment groups
          true
        end

        def supports_blue_green?
          # EC2 and ECS support blue-green deployments
          ec2_platform? || ecs_platform?
        end

        def supports_canary?
          # Lambda supports canary deployments
          lambda_platform?
        end

        def deployment_type_options
          case compute_platform
          when 'Server'
            ['In-place', 'Blue/Green']
          when 'Lambda'
            ['Canary', 'Linear', 'AllAtOnce']
          when 'ECS'
            ['Blue/Green']
          else
            []
          end
        end
      end
    end
      end
    end
  end
end