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
require_relative 'core'
require_relative 'policy'

module Pangea
  module Components
    module ApiGatewayMicroservices
      # Service endpoint configuration
      class ServiceEndpoint < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name, Types::String
        attribute :base_path, Types::String
        attribute :methods, Types::Array.of(ApiMethodConfig)
        attribute :integration, ServiceIntegration
        attribute :transformation, TransformationConfig.default { TransformationConfig.new({}) }
        attribute :rate_limit_override, RateLimitConfig.optional
        attribute :vpc_link_ref, Types::ResourceReference.optional
        attribute :nlb_ref, Types::ResourceReference.optional
      end

      # API documentation configuration
      class DocumentationConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enabled, Types::Bool.default(true)
        attribute :title, Types::String
        attribute :description, Types::String
        attribute :version, Types::String.default('1.0.0')
        attribute :contact_email, Types::String.optional
        attribute :license_name, Types::String.default('Apache 2.0')
        attribute :license_url, Types::String.default('https://www.apache.org/licenses/LICENSE-2.0.html')
      end
    end
  end
end
