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
        # Validators for Lambda function attributes
        module LambdaValidators
          module_function

          def validate_package_type(attrs)
            if attrs[:package_type] == 'Image'
              raise Dry::Struct::Error, "image_uri is required when package_type is 'Image'" if attrs[:image_uri].nil?
              if attrs[:handler] || attrs[:runtime] != 'provided.al2'
                raise Dry::Struct::Error, 'handler and runtime should not be specified for container images'
              end
            else
              raise Dry::Struct::Error, "image_uri can only be used when package_type is 'Image'" if attrs[:image_uri]
              if attrs[:filename].nil? && attrs[:s3_bucket].nil?
                raise Dry::Struct::Error, 'Either filename or s3_bucket/s3_key must be specified for Zip package type'
              end
              raise Dry::Struct::Error, 's3_key is required when s3_bucket is specified' if attrs[:s3_bucket] && attrs[:s3_key].nil?
            end
          end

          def validate_snap_start(attrs)
            return unless attrs[:snap_start] && attrs[:snap_start][:apply_on] != 'None'
            raise Dry::Struct::Error, 'Snap start is only supported for Java runtimes' unless attrs[:runtime]&.start_with?('java')
          end

          def validate_architectures(attrs)
            return unless attrs[:architectures] && attrs[:architectures].size > 1
            raise Dry::Struct::Error, 'Lambda functions can only have one architecture'
          end

          def validate_handler_format(handler, runtime)
            case runtime
            when /^python/
              validate_python_handler(handler)
            when /^nodejs/
              validate_nodejs_handler(handler)
            when /^java/
              validate_java_handler(handler)
            when /^dotnet/
              validate_dotnet_handler(handler)
            when 'go1.x'
              validate_go_handler(handler)
            when /^ruby/
              validate_ruby_handler(handler)
            end
          end

          def validate_python_handler(handler)
            return if handler =~ /\A[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*\z/
            raise Dry::Struct::Error, "Python handler must be in format 'filename.function_name'"
          end

          def validate_nodejs_handler(handler)
            return if handler =~ /\A[a-zA-Z0-9_./-]+\.[a-zA-Z_][a-zA-Z0-9_]*\z/
            raise Dry::Struct::Error, "Node.js handler must be in format 'filename.export'"
          end

          def validate_java_handler(handler)
            return if handler =~ /\A[a-zA-Z_][a-zA-Z0-9_.$]*::[a-zA-Z_][a-zA-Z0-9_]*\z/
            raise Dry::Struct::Error, "Java handler must be in format 'package.Class::method'"
          end

          def validate_dotnet_handler(handler)
            return if handler =~ /\A[a-zA-Z_][a-zA-Z0-9_.$]*::[a-zA-Z_][a-zA-Z0-9_.$]*::[a-zA-Z_][a-zA-Z0-9_]*\z/
            raise Dry::Struct::Error, ".NET handler must be in format 'Assembly::Namespace.Class::Method'"
          end

          def validate_go_handler(handler)
            return if handler =~ /\A[a-zA-Z_][a-zA-Z0-9_]*\z/
            raise Dry::Struct::Error, 'Go handler must be the executable name'
          end

          def validate_ruby_handler(handler)
            return if handler =~ /\A[a-zA-Z_][a-zA-Z0-9_/]*\.[a-zA-Z_][a-zA-Z0-9_]*\z/
            raise Dry::Struct::Error, "Ruby handler must be in format 'filename.method_name'"
          end
        end
      end
    end
  end
end
