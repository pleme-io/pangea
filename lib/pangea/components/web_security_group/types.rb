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
require 'pangea/components/types'
require_relative 'types/validation'
require_relative 'types/port_methods'
require_relative 'types/security_analysis'
require_relative 'types/rules_summary'

module Pangea
  module Components
    module WebSecurityGroup
      module Types
        # WebSecurityGroup component attributes with comprehensive validation
        class WebSecurityGroupAttributes < Dry::Struct
          include PortMethods
          include SecurityAnalysis
          include RulesSummary

          transform_keys(&:to_sym)

          attribute :vpc_ref, Components::Types::VpcReference
          attribute :description, Resources::Types::String.default("Web servers security group")
          attribute :enable_http, Components::Types::Bool.default(true)
          attribute :enable_https, Components::Types::Bool.default(true)
          attribute :enable_ssh, Components::Types::Bool.default(false)
          attribute :http_port, Resources::Types::Port.default(80)
          attribute :https_port, Resources::Types::Port.default(443)
          attribute :ssh_port, Resources::Types::Port.default(22)
          attribute :custom_ports, Resources::Types::Array.of(Resources::Types::Port).default([].freeze)
          attribute :allowed_cidr_blocks, Components::Types::SubnetCidrBlocks.default(["0.0.0.0/0"].freeze)
          attribute :ssh_cidr_blocks, Components::Types::SubnetCidrBlocks.default(["10.0.0.0/8"].freeze)
          attribute :enable_ping, Components::Types::Bool.default(false)
          attribute :enable_outbound_internet, Components::Types::Bool.default(true)
          attribute :enable_vpc_communication, Components::Types::Bool.default(true)
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)
          attribute :security_profile, Resources::Types::String.enum('basic', 'standard', 'strict', 'custom').default('standard')

          # Custom validation for security group configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            Validation.validate(attrs)
            super(attrs)
          end
        end
      end
    end
  end
end
