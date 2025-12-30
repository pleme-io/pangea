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
        module ManagedBlockchainMemberValidation
          def validate_network_id(network_id)
            return if network_id.match?(/\An-[A-Z0-9]{26}\z/)

            raise Dry::Struct::Error, "network_id must be in format 'n-XXXXXXXXXXXXXXXXXXXXXXXXXXXX'"
          end

          def validate_invitation_id(invitation_id)
            return if invitation_id.nil?
            return if invitation_id.match?(/\Ai-[A-Z0-9]{26}\z/)

            raise Dry::Struct::Error, "invitation_id must be in format 'i-XXXXXXXXXXXXXXXXXXXXXXXXXXXX'"
          end

          def validate_member_name(member_name)
            unless member_name.match?(/\A[a-zA-Z][a-zA-Z0-9]*\z/)
              raise Dry::Struct::Error, 'member name must start with a letter and contain only alphanumeric characters'
            end

            return unless member_name.length < 1 || member_name.length > 64

            raise Dry::Struct::Error, 'member name must be between 1 and 64 characters'
          end

          def validate_fabric_configuration(fabric_config)
            validate_admin_username(fabric_config[:admin_username])
            validate_admin_password(fabric_config[:admin_password])
          end

          def validate_admin_username(admin_username)
            unless admin_username.match?(/\A[a-zA-Z0-9]+\z/)
              raise Dry::Struct::Error, 'admin_username must contain only alphanumeric characters'
            end

            return unless admin_username.length < 1 || admin_username.length > 16

            raise Dry::Struct::Error, 'admin_username must be between 1 and 16 characters'
          end

          def validate_admin_password(admin_password)
            if admin_password.length < 8 || admin_password.length > 32
              raise Dry::Struct::Error, 'admin_password must be between 8 and 32 characters'
            end

            return if valid_password_complexity?(admin_password)

            raise Dry::Struct::Error, 'admin_password must contain uppercase, lowercase, number, and special character'
          end

          def valid_password_complexity?(password)
            password.match?(/[A-Z]/) &&
              password.match?(/[a-z]/) &&
              password.match?(/[0-9]/) &&
              password.match?(%r{[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>/?]})
          end
        end
      end
    end
  end
end
