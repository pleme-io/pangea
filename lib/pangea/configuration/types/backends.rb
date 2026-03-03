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

module Pangea
  module ConfigurationTypes
    module Types
      # S3 Backend Configuration
      class S3BackendConfig < Dry::Struct
        attribute :bucket, BucketName
        attribute :key, PathString
        attribute :region, AwsRegion
        attribute? :dynamodb_table, Types::String.optional
        attribute? :encrypt, Types::Bool.default(true)
        attribute? :kms_key_id, Types::String.optional
        attribute? :workspace_key_prefix, Types::String.optional
        attribute? :role_arn, Types::String.optional
        attribute? :session_name, Types::String.optional
        attribute? :external_id, Types::String.optional
        attribute? :assume_role_duration_seconds, Types::Integer.optional
        attribute? :assume_role_policy, Types::String.optional
        attribute? :shared_credentials_file, Types::String.optional
        attribute? :profile, Types::String.optional
        attribute? :skip_credentials_validation, Types::Bool.default(false)
        attribute? :skip_metadata_api_check, Types::Bool.default(false)
        attribute? :force_path_style, Types::Bool.default(false)
        attribute? :max_retries, Types::Integer.optional

        def to_h
          super.compact
        end
      end

      # Local Backend Configuration
      class LocalBackendConfig < Dry::Struct
        attribute :path, PathString.default('terraform.tfstate')
        attribute? :workspace_dir, Types::String.optional

        def to_h
          super.compact
        end
      end

      # Azure Backend Configuration
      class AzureRMBackendConfig < Dry::Struct
        attribute :storage_account_name, Types::String
        attribute :container_name, Types::String
        attribute :key, PathString
        attribute? :environment, Types::String.optional
        attribute? :endpoint, Types::String.optional
        attribute? :snapshot, Types::Bool.default(false)
        attribute? :subscription_id, Types::String.optional
        attribute? :tenant_id, Types::String.optional
        attribute? :client_id, Types::String.optional
        attribute? :client_secret, Types::String.optional
        attribute? :resource_group_name, Types::String.optional
        attribute? :msi_endpoint, Types::String.optional
        attribute? :use_msi, Types::Bool.default(false)
        attribute? :sas_token, Types::String.optional
        attribute? :access_key, Types::String.optional

        def to_h
          super.compact
        end
      end

      # GCS Backend Configuration
      class GCSBackendConfig < Dry::Struct
        attribute :bucket, Types::String
        attribute? :prefix, PathString.optional
        attribute? :credentials, Types::String.optional
        attribute? :access_token, Types::String.optional
        attribute? :impersonate_service_account, Types::String.optional
        attribute? :impersonate_service_account_delegates, Types::Array.of(Types::String).optional

        def to_h
          super.compact
        end
      end
    end
  end
end
