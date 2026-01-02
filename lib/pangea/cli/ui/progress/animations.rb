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
  module CLI
    module UI
      # Progress animations for specific operations
      module Animations
        # Compilation progress with file counter
        def self.compilation(total_files)
          Progress.new.single("Compiling templates", total: total_files) do |bar|
            yield lambda { |file|
              bar.log("  -> #{file}")
              bar.advance
            }
          end
        end

        # Resource creation with parallel bars
        def self.resource_creation(resources)
          Progress.new.multi("Creating resources") do |multi|
            bars = {}

            resources.each do |type, items|
              bars[type] = multi.register(
                type,
                type.capitalize.to_s,
                total: items.count
              )
            end

            yield ->(type) { bars[type]&.advance }
          end
        end

        # State operations with stages
        def self.state_operation(operation)
          stages = case operation
                   when :init
                     ["Checking backend", "Creating bucket", "Enabling versioning", "Setting up locking"]
                   when :lock
                     ["Acquiring lock", "Verifying ownership", "Recording metadata"]
                   when :unlock
                     ["Verifying ownership", "Releasing lock", "Cleaning up"]
                   else
                     ["Starting", "Processing", "Finalizing"]
                   end

          Progress.new.stages("#{operation.capitalize} state", stages: stages) do |progress|
            yield ->(stage) { progress.complete_stage(stage) }
          end
        end
      end
    end
  end
end
