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
          # Validation logic for CodeBuild Project attributes
          module Validation
            class << self
              def validate(attrs)
                validate_source(attrs)
                validate_artifacts(attrs)
                validate_vpc_config(attrs)
                validate_cache(attrs)
                validate_environment_variables(attrs)
              end

              private

              def validate_source(attrs)
                source = attrs.source
                return unless source[:type] != 'CODEPIPELINE' && source[:type] != 'NO_SOURCE'
                return unless source[:location].nil?

                raise Dry::Struct::Error, "Source location is required for source type #{source[:type]}"
              end

              def validate_artifacts(attrs)
                return unless attrs.artifacts[:type] == 'S3' && attrs.artifacts[:location].nil?

                raise Dry::Struct::Error, 'Artifacts location is required for S3 artifact type'
              end

              def validate_vpc_config(attrs)
                return unless attrs.vpc_config

                if attrs.vpc_config[:subnets].empty?
                  raise Dry::Struct::Error, 'At least one subnet is required for VPC configuration'
                end

                return unless attrs.vpc_config[:security_group_ids].empty?

                raise Dry::Struct::Error, 'At least one security group is required for VPC configuration'
              end

              def validate_cache(attrs)
                cache = attrs.cache

                if cache[:type] == 'S3' && cache[:location].nil?
                  raise Dry::Struct::Error, 'Cache location is required for S3 cache type'
                end

                return unless cache[:type] == 'LOCAL' && (cache[:modes].nil? || cache[:modes].empty?)

                raise Dry::Struct::Error, 'At least one cache mode is required for LOCAL cache type'
              end

              def validate_environment_variables(attrs)
                env_vars = attrs.environment[:environment_variables]
                return unless env_vars

                var_names = env_vars.map { |v| v[:name] }
                return unless var_names.size != var_names.uniq.size

                raise Dry::Struct::Error, 'Environment variable names must be unique'
              end
            end
          end
        end
      end
    end
  end
end
