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
          def administrative_user?
            name.downcase.include?('admin') ||
              name.downcase.include?('root') ||
              name.downcase.include?('super')
          end

          def service_user?
            name.downcase.include?('service') ||
              name.downcase.include?('svc') ||
              name.downcase.include?('app') ||
              name.downcase.include?('system')
          end

          def human_user?
            !service_user? && !administrative_user? && name.include?('.')
          end

          def organizational_path?
            path != '/' && path.include?('/')
          end

          def organizational_unit
            return nil unless organizational_path?

            path.split('/').reject(&:empty?).first
          end

          def user_arn(account_id = '123456789012')
            "arn:aws:iam::#{account_id}:user#{path}#{name}"
          end

          def has_permissions_boundary?
            !permissions_boundary.nil?
          end

          def permissions_boundary_policy_name
            return nil unless has_permissions_boundary?

            permissions_boundary.split('/').last
          end

          def user_category
            if administrative_user?
              :administrative
            elsif service_user?
              :service_account
            elsif human_user?
              :human_user
            else
              :generic
            end
          end

          def security_risk_level
            if administrative_user? && !has_permissions_boundary?
              :high
            elsif service_user? && !has_permissions_boundary?
              :medium
            elsif has_permissions_boundary?
              :low
            else
              :medium
            end
          end

          def validate_user_security!
            warnings = []

            if administrative_user? && !has_permissions_boundary?
              warnings << "Administrative user '#{name}' should have a permissions boundary"
            end

            unsafe_names = %w[root admin administrator sa service]
            if unsafe_names.any? { |unsafe| name.downcase == unsafe }
              warnings << "User name '#{name}' matches common attack targets - consider more specific naming"
            end

            if path == '/' && !name.include?('.')
              warnings << "User '#{name}' is in root path - consider organizational path structure"
            end

            return if warnings.empty?

            puts "IAM User Security Warnings for '#{name}':"
            warnings.each { |warning| puts "  - #{warning}" }
          end

          def self.generate_secure_password(length = 16)
            charset = [
              ('A'..'Z').to_a,
              ('a'..'z').to_a,
              ('0'..'9').to_a,
              ['!', '@', '#', '$', '%', '^', '&', '*']
            ].flatten

            Array.new(length) { charset.sample }.join
          end
        end
      end
    end
  end
end
