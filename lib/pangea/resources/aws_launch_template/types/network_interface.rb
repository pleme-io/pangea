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
        # Network interface specification
        class NetworkInterface < Dry::Struct
          transform_keys(&:to_sym)

          attribute :associate_public_ip_address, Resources::Types::Bool.optional.default(nil)
          attribute :delete_on_termination, Resources::Types::Bool.default(true)
          attribute :description, Resources::Types::String.optional.default(nil)
          attribute :device_index, Resources::Types::Integer.default(0)
          attribute :groups, Resources::Types::Array.of(Resources::Types::String).default([].freeze)
          attribute :network_interface_id, Resources::Types::String.optional.default(nil)
          attribute :private_ip_address, Resources::Types::String.optional.default(nil)
          attribute :subnet_id, Resources::Types::String.optional.default(nil)

          def to_h
            attributes.reject { |_, v| v.nil? || (v.respond_to?(:empty?) && v.empty?) }
          end
        end
      end
    end
  end
end
