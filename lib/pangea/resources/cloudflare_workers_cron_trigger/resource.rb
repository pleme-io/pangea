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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_workers_cron_trigger/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Workers Cron Trigger resource module that self-registers
    module CloudflareWorkersCronTrigger
      # Create a Cloudflare Workers Cron Trigger
      #
      # Schedules Workers to run on a cron schedule. Perfect for periodic
      # tasks like data cleanup, report generation, and scheduled processing.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Cron trigger attributes
      # @option attributes [String] :account_id Cloudflare account ID (required)
      # @option attributes [String] :script_name Worker script name (required)
      # @option attributes [Array<String>] :schedules Cron expressions (required)
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Run worker every 30 minutes
      #   cloudflare_workers_cron_trigger(:cleanup, {
      #     account_id: "a" * 32,
      #     script_name: "cleanup-worker",
      #     schedules: ["*/30 * * * *"]
      #   })
      #
      # @example Run worker daily at 2 AM
      #   cloudflare_workers_cron_trigger(:daily_report, {
      #     account_id: "a" * 32,
      #     script_name: "report-generator",
      #     schedules: ["0 2 * * *"]
      #   })
      #
      # @example Multiple schedules for different times
      #   cloudflare_workers_cron_trigger(:multi_schedule, {
      #     account_id: "a" * 32,
      #     script_name: "sync-worker",
      #     schedules: [
      #       "0 8 * * *",   # 8 AM daily
      #       "0 20 * * *"   # 8 PM daily
      #     ]
      #   })
      def cloudflare_workers_cron_trigger(name, attributes = {})
        # Validate attributes using dry-struct
        cron_attrs = Cloudflare::Types::WorkersCronTriggerAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_workers_cron_trigger, name) do
          account_id cron_attrs.account_id
          script_name cron_attrs.script_name
          schedules cron_attrs.schedules
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_workers_cron_trigger',
          name: name,
          resource_attributes: cron_attrs.to_h,
          outputs: {
            id: "${cloudflare_workers_cron_trigger.#{name}.id}",
            trigger_id: "${cloudflare_workers_cron_trigger.#{name}.id}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareWorkersCronTrigger
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
