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
        module EmrClusterValidation
          def validate_cluster_name(name)
            raise Dry::Struct::Error, 'Cluster name must start with letter or underscore and contain only alphanumeric characters, underscores, and hyphens' unless name =~ /\A[a-zA-Z_][a-zA-Z0-9_-]*\z/
            raise Dry::Struct::Error, 'Cluster name must be 256 characters or less' if name.length > 256
          end

          def validate_release_label(label)
            raise Dry::Struct::Error, 'Release label must be in format emr-x.x.x' unless label =~ /\Aemr-\d+\.\d+\.\d+\z/
          end

          def validate_service_role(role)
            raise Dry::Struct::Error, 'Service role must be an IAM role ARN or EMR_DefaultRole' unless role.match(/\A(arn:aws:iam::\d{12}:role\/|EMR_DefaultRole)/i)
          end

          def validate_instance_profile(profile)
            raise Dry::Struct::Error, 'Instance profile must be an IAM instance profile ARN or EMR_EC2_DefaultRole' unless profile.match(/\A(arn:aws:iam::\d{12}:instance-profile\/|EMR_EC2_DefaultRole)/i)
          end

          def validate_log_uri(uri)
            return if uri.nil?
            raise Dry::Struct::Error, 'Log URI must be an S3 URL (s3://bucket/path)' unless uri.match(/\As3:\/\//)
          end

          def validate_subnet_config(ec2_attrs)
            raise Dry::Struct::Error, 'Cannot specify both subnet_id and subnet_ids' if ec2_attrs[:subnet_id] && ec2_attrs[:subnet_ids]
          end
        end
      end
    end
  end
end
