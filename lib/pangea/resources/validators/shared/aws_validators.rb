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
    module Validators
      module SharedValidators
        # AWS-specific validators (region, AZ, ARN)
        module AwsValidators
          # Validate AWS region format
          #
          # @param value [String] The region string
          # @return [String] The validated region
          def valid_aws_region!(value)
            unless value.match?(/\A[a-z]{2}-[a-z]+-\d\z/)
              raise ValidationError, "Invalid AWS region format: #{value}"
            end
            value
          end

          # Validate AWS availability zone format
          #
          # @param value [String] The AZ string
          # @return [String] The validated AZ
          def valid_aws_az!(value)
            unless value.match?(/\A[a-z]{2}-[a-z]+-\d[a-z]\z/)
              raise ValidationError, "Invalid AWS AZ format: #{value}"
            end
            value
          end

          # Validate AWS ARN format
          #
          # @param value [String] The ARN string
          # @param service [String, nil] Optional service name to validate
          # @return [String] The validated ARN
          def valid_arn!(value, service: nil)
            pattern = if service
                        /\Aarn:aws:#{Regexp.escape(service)}:[a-z0-9-]*:\d{12}:.+\z/
                      else
                        /\Aarn:aws:[a-z0-9-]+:[a-z0-9-]*:\d{12}:.+\z/
                      end

            unless value.match?(pattern)
              raise ValidationError, "Invalid ARN format: #{value}"
            end
            value
          end
        end
      end
    end
  end
end
