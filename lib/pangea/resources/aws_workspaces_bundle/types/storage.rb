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
        # User storage configuration
        class UserStorageConfigurationType < Dry::Struct
          transform_keys(&:to_sym)

          attribute :capacity, Resources::Types::Coercible::String.constrained(
            format: /\A\d+\z/
          ).constructor { |value|
            capacity_int = value.to_i
            unless (10..2000).include?(capacity_int)
              raise Dry::Types::ConstraintError, 'User storage capacity must be between 10 and 2000 GB'
            end
            value
          }

          def capacity_gb
            capacity.to_i
          end

          def is_ssd?
            true
          end
        end

        # Root storage configuration
        class RootStorageConfigurationType < Dry::Struct
          transform_keys(&:to_sym)

          attribute :capacity, Resources::Types::Coercible::String.constrained(
            format: /\A\d+\z/
          ).constructor { |value|
            capacity_int = value.to_i
            unless (80..2000).include?(capacity_int)
              raise Dry::Types::ConstraintError, 'Root storage capacity must be between 80 and 2000 GB'
            end
            value
          }

          def capacity_gb
            capacity.to_i
          end

          def is_ssd?
            true
          end
        end
      end
    end
  end
end
