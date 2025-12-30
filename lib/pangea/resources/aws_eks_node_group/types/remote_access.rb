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
        # Remote access configuration
        class RemoteAccess < Dry::Struct
          transform_keys(&:to_sym)

          attribute :ec2_ssh_key, Pangea::Resources::Types::String.optional.default(nil)
          attribute :source_security_group_ids, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)

          def to_h
            hash = {}
            hash[:ec2_ssh_key] = ec2_ssh_key if ec2_ssh_key
            hash[:source_security_group_ids] = source_security_group_ids if source_security_group_ids.any?
            hash
          end
        end
      end
    end
  end
end
