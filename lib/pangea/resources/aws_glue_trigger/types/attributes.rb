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

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        module GlueTriggerTypes
          # Core attribute definitions for AWS Glue Trigger resources
          module Attributes
            def self.included(base)
              base.class_eval do
                # Trigger name (required)
                attribute :name, Resources::Types::String

                # Trigger type (required)
                attribute :type, Resources::Types::String.enum("SCHEDULED", "CONDITIONAL", "ON_DEMAND")

                # Trigger description
                attribute :description, Resources::Types::String.optional

                # Enable/disable trigger
                attribute :enabled, Resources::Types::Bool.default(true)

                # Schedule expression for SCHEDULED triggers
                attribute :schedule, Resources::Types::String.optional

                # Start time for scheduled triggers
                attribute :start_on_creation, Resources::Types::Bool.optional

                # Workflow name if part of workflow
                attribute :workflow_name, Resources::Types::String.optional

                # Actions to execute when trigger fires
                attribute :actions, Resources::Types::Array.of(
                  Types::Hash.schema(
                    job_name?: Types::String.optional,
                    crawler_name?: Types::String.optional,
                    arguments?: Types::Hash.map(Types::String, Types::String).optional,
                    timeout?: Types::Integer.optional,
                    security_configuration?: Types::String.optional,
                    notification_property?: Types::Hash.schema(
                      notify_delay_after?: Types::Integer.optional
                    ).optional
                  )
                ).default([].freeze)

                # Predicate for CONDITIONAL triggers
                attribute :predicate, Resources::Types::Hash.schema(
                  logical?: Types::String.enum("AND", "ANY").optional,
                  conditions?: Types::Array.of(
                    Types::Hash.schema(
                      logical_operator?: Types::String.enum("EQUALS").optional,
                      job_name?: Types::String.optional,
                      state?: Types::String.enum("SUCCEEDED", "STOPPED", "FAILED", "TIMEOUT").optional,
                      crawler_name?: Types::String.optional,
                      crawl_state?: Types::String.enum("SUCCEEDED", "CANCELLED", "FAILED").optional
                    )
                  ).optional
                ).optional

                # Event batching configuration
                attribute :event_batching_condition, Resources::Types::Hash.schema(
                  batch_size: Types::Integer.constrained(gteq: 1, lteq: 100),
                  batch_window?: Types::Integer.constrained(gteq: 900, lteq: 900).optional
                ).optional

                # Tags
                attribute :tags, Resources::Types::AwsTags.default({}.freeze)
              end
            end
          end
        end
      end
    end
  end
end
