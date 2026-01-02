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
        module S3ObjectInstanceMethods
          def has_source_file?
            !source.nil?
          end

          def has_inline_content?
            !content.nil?
          end

          def encrypted?
            !server_side_encryption.nil?
          end

          def kms_encrypted?
            server_side_encryption == 'aws:kms'
          end

          def has_metadata?
            metadata.any?
          end

          def has_tags?
            tags.any?
          end

          def object_lock_enabled?
            !object_lock_mode.nil?
          end

          def legal_hold_enabled?
            object_lock_legal_hold_status == 'ON'
          end

          def is_website_redirect?
            !website_redirect.nil?
          end

          def source_file_extension
            return nil unless source

            File.extname(source).downcase
          end

          def inferred_content_type
            return content_type if content_type
            return nil unless source

            mime_type_for_extension(source_file_extension)
          end

          def estimated_size
            return content.bytesize if content
            return File.size(source) if source && File.exist?(source)

            nil
          end

          def content_source_type
            return 'file' if source
            return 'inline' if content

            'unknown'
          end

          private

          def mime_type_for_extension(ext)
            MIME_TYPE_MAP[ext] || 'application/octet-stream'
          end

          MIME_TYPE_MAP = {
            '.html' => 'text/html',
            '.htm' => 'text/html',
            '.css' => 'text/css',
            '.js' => 'application/javascript',
            '.json' => 'application/json',
            '.xml' => 'application/xml',
            '.pdf' => 'application/pdf',
            '.jpg' => 'image/jpeg',
            '.jpeg' => 'image/jpeg',
            '.png' => 'image/png',
            '.gif' => 'image/gif',
            '.svg' => 'image/svg+xml',
            '.txt' => 'text/plain',
            '.md' => 'text/markdown',
            '.zip' => 'application/zip'
          }.freeze
        end
      end
    end
  end
end
