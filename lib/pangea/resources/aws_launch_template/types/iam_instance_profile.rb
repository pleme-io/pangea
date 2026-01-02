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
        # IAM instance profile configuration
        class IamInstanceProfile < Dry::Struct
          transform_keys(&:to_sym)

          attribute :arn, Resources::Types::String.optional.default(nil)
          attribute :name, Resources::Types::String.optional.default(nil)

          def self.new(attributes)
            return super if attributes.is_a?(Hash)

            # Allow string input for name
            if attributes.is_a?(String)
              super(name: attributes)
            else
              super(attributes)
            end
          end

          def to_h
            { arn: arn, name: name }.compact
          end
        end
      end
    end
  end
end
