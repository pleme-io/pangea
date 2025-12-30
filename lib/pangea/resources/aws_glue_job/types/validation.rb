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
        # Validation module for AWS Glue Job attributes
        module GlueJobValidation
          def validate_job_name(name)
            unless name =~ /\A[a-zA-Z_][a-zA-Z0-9_-]*\z/
              raise Dry::Struct::Error,
                    'Job name must start with letter or underscore and contain only alphanumeric characters, underscores, and hyphens'
            end
            raise Dry::Struct::Error, 'Job name must be 255 characters or less' if name.length > 255
          end

          def validate_role_arn(role_arn)
            unless role_arn.match(/\Aarn:aws:iam::\d{12}:role\//)
              raise Dry::Struct::Error, 'Role ARN must be in format arn:aws:iam::account:role/role-name'
            end
          end

          def validate_script_location(command)
            script_location = command[:script_location]
            unless script_location.match(/\As3:\/\//)
              raise Dry::Struct::Error, 'Script location must be an S3 URL (s3://bucket/path)'
            end
          end

          def validate_worker_configuration(attrs)
            if attrs.worker_type && !attrs.number_of_workers
              raise Dry::Struct::Error, 'number_of_workers is required when worker_type is specified'
            end

            if attrs.number_of_workers && !attrs.worker_type
              raise Dry::Struct::Error, 'worker_type is required when number_of_workers is specified'
            end

            if attrs.max_capacity && (attrs.worker_type || attrs.number_of_workers)
              raise Dry::Struct::Error, 'max_capacity cannot be used with worker_type/number_of_workers configuration'
            end
          end

          def validate_timeout(timeout)
            return if timeout.nil?
            if timeout < 1 || timeout > 2880
              raise Dry::Struct::Error, 'Timeout must be between 1 and 2880 minutes (48 hours)'
            end
          end
        end
      end
    end
  end
end
