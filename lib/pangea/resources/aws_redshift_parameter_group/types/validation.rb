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

module Pangea
  module Resources
    module AWS
      module Types
        module RedshiftParameterGroupValidation
          def self.validate!(attrs)
            validate_name_format!(attrs.name)
            validate_name_length!(attrs.name)
            validate_parameter_names!(attrs.parameters)
          end

          def self.validate_name_format!(name)
            return if name =~ /\A[a-z][a-z0-9\-]*\z/

            raise Dry::Struct::Error,
                  'Parameter group name must start with lowercase letter and contain only lowercase letters, numbers, and hyphens'
          end

          def self.validate_name_length!(name)
            return unless name.length > 255

            raise Dry::Struct::Error, 'Parameter group name must be 255 characters or less'
          end

          def self.validate_parameter_names!(parameters)
            parameters.each do |param|
              next if param[:name] =~ /\A[a-z_]+\z/

              raise Dry::Struct::Error,
                    "Parameter name '#{param[:name]}' must contain only lowercase letters and underscores"
            end
          end
        end
      end
    end
  end
end
