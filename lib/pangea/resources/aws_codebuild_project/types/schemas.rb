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
        class CodeBuildProjectAttributes
          # Schema definitions for CodeBuild Project nested types
          module Schemas
            T = Resources::Types

            # Source configuration schema
            SOURCE = T::Hash.schema(
              type: T::String.enum('CODECOMMIT', 'CODEPIPELINE', 'GITHUB', 'GITHUB_ENTERPRISE', 'BITBUCKET', 'S3', 'NO_SOURCE'),
              location?: T::String.optional,
              git_clone_depth?: T::Integer.constrained(gteq: 0).optional,
              buildspec?: T::String.optional,
              report_build_status?: T::Bool.optional,
              insecure_ssl?: T::Bool.optional,
              git_submodules_config?: T::Hash.schema(
                fetch_submodules: T::Bool
              ).optional,
              auth?: T::Hash.schema(
                type: T::String.enum('OAUTH'),
                resource?: T::String.optional
              ).optional
            )

            # Artifacts configuration schema
            ARTIFACTS = T::Hash.schema(
              type: T::String.enum('CODEPIPELINE', 'S3', 'NO_ARTIFACTS'),
              location?: T::String.optional,
              name?: T::String.optional,
              namespace_type?: T::String.enum('NONE', 'BUILD_ID').optional,
              packaging?: T::String.enum('NONE', 'ZIP').optional,
              path?: T::String.optional,
              encryption_disabled?: T::Bool.optional,
              artifact_identifier?: T::String.optional,
              override_artifact_name?: T::Bool.optional
            )

            # Secondary source schema
            SECONDARY_SOURCE = T::Hash.schema(
              source_identifier: T::String,
              type: T::String.enum('CODECOMMIT', 'CODEPIPELINE', 'GITHUB', 'S3'),
              location?: T::String.optional,
              git_clone_depth?: T::Integer.optional,
              buildspec?: T::String.optional,
              report_build_status?: T::Bool.optional,
              insecure_ssl?: T::Bool.optional
            )

            # Secondary artifact schema
            SECONDARY_ARTIFACT = T::Hash.schema(
              artifact_identifier: T::String,
              type: T::String.enum('S3'),
              location?: T::String.optional,
              name?: T::String.optional,
              namespace_type?: T::String.enum('NONE', 'BUILD_ID').optional,
              packaging?: T::String.enum('NONE', 'ZIP').optional,
              path?: T::String.optional,
              encryption_disabled?: T::Bool.optional,
              override_artifact_name?: T::Bool.optional
            )

            # Environment configuration schema
            ENVIRONMENT = T::Hash.schema(
              type: T::String.enum('LINUX_CONTAINER', 'LINUX_GPU_CONTAINER', 'WINDOWS_CONTAINER', 'WINDOWS_SERVER_2019_CONTAINER', 'ARM_CONTAINER'),
              image: T::String,
              compute_type: T::String.enum('BUILD_GENERAL1_SMALL', 'BUILD_GENERAL1_MEDIUM', 'BUILD_GENERAL1_LARGE', 'BUILD_GENERAL1_2XLARGE'),
              environment_variables?: T::Array.of(
                T::Hash.schema(
                  name: T::String,
                  value: T::String,
                  type?: T::String.enum('PLAINTEXT', 'PARAMETER_STORE', 'SECRETS_MANAGER').optional
                )
              ).optional,
              privileged_mode?: T::Bool.optional,
              certificate?: T::String.optional,
              registry_credential?: T::Hash.schema(
                credential: T::String,
                credential_provider: T::String.enum('SECRETS_MANAGER')
              ).optional,
              image_pull_credentials_type?: T::String.enum('CODEBUILD', 'SERVICE_ROLE').optional
            )

            # Cache configuration schema
            CACHE = T::Hash.schema(
              type: T::String.enum('NO_CACHE', 'S3', 'LOCAL'),
              location?: T::String.optional,
              modes?: T::Array.of(
                T::String.enum('LOCAL_DOCKER_LAYER_CACHE', 'LOCAL_SOURCE_CACHE', 'LOCAL_CUSTOM_CACHE')
              ).optional
            )

            # VPC configuration schema
            VPC_CONFIG = T::Hash.schema(
              vpc_id: T::String,
              subnets: T::Array.of(T::String).constrained(min_size: 1),
              security_group_ids: T::Array.of(T::String).constrained(min_size: 1)
            )

            # Logs configuration schema
            LOGS_CONFIG = T::Hash.schema(
              cloudwatch_logs?: T::Hash.schema(
                status?: T::String.enum('ENABLED', 'DISABLED').optional,
                group_name?: T::String.optional,
                stream_name?: T::String.optional
              ).optional,
              s3_logs?: T::Hash.schema(
                status?: T::String.enum('ENABLED', 'DISABLED').optional,
                location?: T::String.optional,
                encryption_disabled?: T::Bool.optional
              ).optional
            )

            # Build batch configuration schema
            BUILD_BATCH_CONFIG = T::Hash.schema(
              service_role: T::String,
              combine_artifacts?: T::Bool.optional,
              restrictions?: T::Hash.schema(
                compute_types_allowed?: T::Array.of(T::String).optional,
                maximum_builds_allowed?: T::Integer.optional
              ).optional,
              timeout_in_mins?: T::Integer.optional
            )

            # File system location schema
            FILE_SYSTEM_LOCATION = T::Hash.schema(
              type: T::String.enum('EFS'),
              location: T::String,
              mount_point: T::String,
              identifier: T::String,
              mount_options?: T::String.optional
            )
          end
        end
      end
    end
  end
end
