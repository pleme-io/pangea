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
        class IamUserAttributes < Dry::Struct
          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            validate_user_name!(attrs)
            validate_path!(attrs)
            validate_permissions_boundary!(attrs)
            attrs.validate_user_security!

            attrs
          end

          class << self
            private

            def validate_user_name!(attrs)
              unless attrs.name.match?(/\A[a-zA-Z0-9+=,.@_-]+\z/)
                raise Dry::Struct::Error, 'User name must contain only alphanumeric characters and +=,.@_-'
              end

              return unless attrs.name.length > 64

              raise Dry::Struct::Error, 'User name cannot exceed 64 characters'
            end

            def validate_path!(attrs)
              unless attrs.path.match?(/\A\/[\w+=,.@-]*\/?\z/)
                raise Dry::Struct::Error, "Path must start with '/' and contain only valid characters"
              end

              return unless attrs.path.length > 512

              raise Dry::Struct::Error, 'Path cannot exceed 512 characters'
            end

            def validate_permissions_boundary!(attrs)
              return unless attrs.permissions_boundary
              return if attrs.permissions_boundary.match?(/\Aarn:aws:iam::[0-9]{12}:policy\/.*\z/)

              raise Dry::Struct::Error, 'permissions_boundary must be a valid IAM policy ARN'
            end
          end
        end
      end
    end
  end
end
