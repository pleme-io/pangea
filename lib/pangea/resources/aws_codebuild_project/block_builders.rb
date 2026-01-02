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
      # Block builders for AWS CodeBuild Project resource
      # Extracts complex nested block building logic for cleaner resource definition
      module CodeBuildBlockBuilders
        extend self

        def apply_source(ctx, source_attrs)
          ctx.source do
            type source_attrs[:type]
            location source_attrs[:location] if source_attrs[:location]
            git_clone_depth source_attrs[:git_clone_depth] if source_attrs[:git_clone_depth]
            buildspec source_attrs[:buildspec] if source_attrs[:buildspec]
            report_build_status source_attrs[:report_build_status] if source_attrs.key?(:report_build_status)
            insecure_ssl source_attrs[:insecure_ssl] if source_attrs.key?(:insecure_ssl)

            if source_attrs[:git_submodules_config]
              git_submodules_config do
                fetch_submodules source_attrs[:git_submodules_config][:fetch_submodules]
              end
            end

            if source_attrs[:auth]
              auth do
                type source_attrs[:auth][:type]
                resource source_attrs[:auth][:resource] if source_attrs[:auth][:resource]
              end
            end
          end
        end

        def apply_secondary_sources(ctx, secondary_sources)
          secondary_sources.each do |src|
            ctx.secondary_sources do
              source_identifier src[:source_identifier]
              type src[:type]
              location src[:location] if src[:location]
              git_clone_depth src[:git_clone_depth] if src[:git_clone_depth]
              buildspec src[:buildspec] if src[:buildspec]
              report_build_status src[:report_build_status] if src.key?(:report_build_status)
              insecure_ssl src[:insecure_ssl] if src.key?(:insecure_ssl)
            end
          end
        end

        def apply_artifacts(ctx, artifacts_attrs)
          ctx.artifacts do
            type artifacts_attrs[:type]
            location artifacts_attrs[:location] if artifacts_attrs[:location]
            name artifacts_attrs[:name] if artifacts_attrs[:name]
            namespace_type artifacts_attrs[:namespace_type] if artifacts_attrs[:namespace_type]
            packaging artifacts_attrs[:packaging] if artifacts_attrs[:packaging]
            path artifacts_attrs[:path] if artifacts_attrs[:path]
            encryption_disabled artifacts_attrs[:encryption_disabled] if artifacts_attrs.key?(:encryption_disabled)
            artifact_identifier artifacts_attrs[:artifact_identifier] if artifacts_attrs[:artifact_identifier]
            override_artifact_name artifacts_attrs[:override_artifact_name] if artifacts_attrs.key?(:override_artifact_name)
          end
        end

        def apply_secondary_artifacts(ctx, secondary_artifacts)
          secondary_artifacts.each do |art|
            ctx.secondary_artifacts do
              artifact_identifier art[:artifact_identifier]
              type art[:type]
              location art[:location] if art[:location]
              name art[:name] if art[:name]
              namespace_type art[:namespace_type] if art[:namespace_type]
              packaging art[:packaging] if art[:packaging]
              path art[:path] if art[:path]
              encryption_disabled art[:encryption_disabled] if art.key?(:encryption_disabled)
              override_artifact_name art[:override_artifact_name] if art.key?(:override_artifact_name)
            end
          end
        end

        def apply_environment(ctx, env_attrs)
          ctx.environment do
            type env_attrs[:type]
            image env_attrs[:image]
            compute_type env_attrs[:compute_type]
            privileged_mode env_attrs[:privileged_mode] if env_attrs.key?(:privileged_mode)
            certificate env_attrs[:certificate] if env_attrs[:certificate]
            image_pull_credentials_type env_attrs[:image_pull_credentials_type] if env_attrs[:image_pull_credentials_type]

            env_attrs[:environment_variables]&.each do |env_var|
              environment_variable do
                name env_var[:name]
                value env_var[:value]
                type env_var[:type] if env_var[:type]
              end
            end

            if env_attrs[:registry_credential]
              registry_credential do
                credential env_attrs[:registry_credential][:credential]
                credential_provider env_attrs[:registry_credential][:credential_provider]
              end
            end
          end
        end

        def apply_logs_config(ctx, logs_config)
          return unless logs_config.any?

          ctx.logs_config do
            if logs_config[:cloudwatch_logs]
              cw = logs_config[:cloudwatch_logs]
              cloudwatch_logs do
                status cw[:status] if cw[:status]
                group_name cw[:group_name] if cw[:group_name]
                stream_name cw[:stream_name] if cw[:stream_name]
              end
            end

            if logs_config[:s3_logs]
              s3 = logs_config[:s3_logs]
              s3_logs do
                status s3[:status] if s3[:status]
                location s3[:location] if s3[:location]
                encryption_disabled s3[:encryption_disabled] if s3.key?(:encryption_disabled)
              end
            end
          end
        end

        def apply_build_batch_config(ctx, batch_config)
          return unless batch_config

          ctx.build_batch_config do
            service_role batch_config[:service_role]
            combine_artifacts batch_config[:combine_artifacts] if batch_config.key?(:combine_artifacts)
            timeout_in_mins batch_config[:timeout_in_mins] if batch_config[:timeout_in_mins]

            if batch_config[:restrictions]
              restrictions do
                r = batch_config[:restrictions]
                compute_types_allowed r[:compute_types_allowed] if r[:compute_types_allowed]
                maximum_builds_allowed r[:maximum_builds_allowed] if r[:maximum_builds_allowed]
              end
            end
          end
        end
      end
    end
  end
end
