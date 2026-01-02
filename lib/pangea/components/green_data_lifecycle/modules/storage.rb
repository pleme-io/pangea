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
  module Components
    module GreenDataLifecycle
      # S3 bucket resources for Green Data Lifecycle component
      module Storage
        private

        def create_primary_bucket(input)
          bucket_name = input.bucket_prefix ? "#{input.bucket_prefix}-#{input.name}" : input.name

          aws_s3_bucket(:"#{input.name}-primary", {
            bucket: bucket_name,
            tags: storage_tags(input, "primary-storage")
          })
        end

        def create_archive_bucket(input)
          bucket_name = if input.bucket_prefix
                          "#{input.bucket_prefix}-#{input.name}-archive"
                        else
                          "#{input.name}-archive"
                        end

          aws_s3_bucket(:"#{input.name}-archive", {
            bucket: bucket_name,
            tags: storage_tags(input, "archive-storage")
          })
        end
      end
    end
  end
end
