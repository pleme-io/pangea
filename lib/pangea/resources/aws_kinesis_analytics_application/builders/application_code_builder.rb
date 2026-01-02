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
      module KinesisAnalyticsApplication
        module Builders
          # Builds the application_code_configuration block for Kinesis Analytics
          module ApplicationCodeBuilder
            extend self

            # Build the application code configuration block
            # @param context [Object] The DSL context for building Terraform blocks
            # @param code_config [Hash] The application code configuration hash
            def build(context, code_config)
              return unless code_config

              context.application_code_configuration do
                code_content_type code_config[:code_content_type]

                code_content do
                  content = code_config[:code_content]
                  build_code_content(self, content)
                end
              end
            end

            private

            def build_code_content(context, content)
              context.text_content content[:text_content] if content[:text_content]
              context.zip_file_content content[:zip_file_content] if content[:zip_file_content]

              build_s3_content_location(context, content[:s3_content_location]) if content[:s3_content_location]
            end

            def build_s3_content_location(context, s3_location)
              context.s3_content_location do
                bucket_arn s3_location[:bucket_arn]
                file_key s3_location[:file_key]
                object_version s3_location[:object_version] if s3_location[:object_version]
              end
            end
          end
        end
      end
    end
  end
end
