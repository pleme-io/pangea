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
require 'pangea/resources/types'

module Pangea
  module Resources
    module AwsIotanalyticsDatasetTypes
      # Trigger configuration for dataset content generation
      class Trigger < Dry::Struct
        schema schema.strict

        # Schedule trigger configuration
        class Schedule < Dry::Struct
          schema schema.strict

          # Schedule expression (cron or rate)
          attribute :schedule_expression, Resources::Types::String
        end

        attribute? :schedule, Schedule.optional

        # Triggering dataset configuration
        class TriggeringDataset < Dry::Struct
          schema schema.strict

          # Name of triggering dataset
          attribute :name, Resources::Types::String
        end

        attribute? :triggering_dataset, TriggeringDataset.optional
      end
    end
  end
end
