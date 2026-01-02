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
        module MediaLiveInput
          # Helper methods for MediaLiveInputAttributes
          module Helpers
            def push_input?
              %w[UDP_PUSH RTP_PUSH RTMP_PUSH].include?(type)
            end

            def pull_input?
              %w[RTMP_PULL URL_PULL].include?(type)
            end

            def file_input?
              %w[MP4_FILE TS_FILE].include?(type)
            end

            def device_input?
              type == 'INPUT_DEVICE'
            end

            def mediaconnect_input?
              type == 'MEDIACONNECT'
            end

            def cdi_input?
              type == 'AWS_CDI'
            end

            def single_pipeline?
              input_class == 'SINGLE_PIPELINE'
            end

            def standard_input?
              input_class == 'STANDARD'
            end

            def has_redundancy?
              standard_input? && (destinations.size > 1 || sources.size > 1)
            end

            def destination_count
              destinations.size
            end

            def source_count
              sources.size
            end

            def device_count
              input_devices.size
            end

            def mediaconnect_flow_count
              media_connect_flows.size
            end

            def has_vpc_config?
              vpc[:subnet_ids] && vpc[:subnet_ids].any?
            end

            def has_security_groups?
              input_security_groups.any? || (vpc[:security_group_ids] && vpc[:security_group_ids].any?)
            end

            def requires_role?
              mediaconnect_input? || has_vpc_config?
            end

            def supports_failover?
              standard_input? && (push_input? || pull_input?)
            end

            def is_live_input?
              !file_input?
            end
          end
        end
      end
    end
  end
end
