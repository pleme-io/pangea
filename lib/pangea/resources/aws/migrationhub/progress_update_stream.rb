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
      module MigrationHub
        # AWS Migration Hub Progress Update Stream resource
        # This resource manages progress update streams which are used to track
        # migration progress for applications and resources. Streams provide
        # a centralized way to monitor migration status across different tools.
        #
        # @see https://docs.aws.amazon.com/migrationhub/latest/ug/tracking-migration-progress.html
        module ProgressUpdateStream
          # Creates an AWS Migration Hub Progress Update Stream
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the stream
          # @option attributes [String] :progress_update_stream_name The name of the progress update stream (required)
          # @option attributes [String] :dry_run Whether this is a dry run (default: false)
          #
          # @example Basic progress update stream
          #   aws_migrationhub_progress_update_stream(:migration_tracking, {
          #     progress_update_stream_name: "ApplicationMigrationProgress"
          #   })
          #
          # @example Progress update stream for specific migration wave
          #   aws_migrationhub_progress_update_stream(:wave_1_progress, {
          #     progress_update_stream_name: "Wave1-ERP-Migration",
          #     dry_run: false
          #   })
          #
          # @example Multiple streams for different migration phases
          #   [
          #     "Discovery-Phase",
          #     "Planning-Phase", 
          #     "Migration-Phase",
          #     "Validation-Phase"
          #   ].each_with_index do |phase, index|
          #     aws_migrationhub_progress_update_stream(:"#{phase.downcase.gsub('-', '_')}_stream", {
          #       progress_update_stream_name: phase
          #     })
          #   end
          #
          # @return [ProgressUpdateStreamResource] The progress update stream resource
          def aws_migrationhub_progress_update_stream(name, attributes = {})
            resource :aws_migrationhub_progress_update_stream, name do
              progress_update_stream_name attributes[:progress_update_stream_name] if attributes[:progress_update_stream_name]
              dry_run attributes[:dry_run] if attributes.key?(:dry_run)
            end
          end
        end
      end
    end
  end
end