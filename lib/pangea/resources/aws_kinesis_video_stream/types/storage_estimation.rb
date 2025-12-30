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
        # Storage and cost estimation for Kinesis Video Stream
        module StorageEstimation
          # Kinesis Video Streams pricing (approximate, varies by region)
          INGESTION_COST_PER_GB = 0.0085
          STORAGE_COST_PER_GB_MONTH = 0.023

          def estimated_storage_gb_per_hour
            # Rough estimates based on media type and typical bitrates
            case media_type.downcase
            when /h264/
              # H.264: ~1-8 Mbps for typical video streams
              # Assume average 4 Mbps = 0.5 MB/s = 1.8 GB/hour
              1.8
            when /h265/, /hevc/
              # H.265/HEVC: ~50% more efficient than H.264
              # Assume average 2.5 Mbps = 0.31 MB/s = 1.1 GB/hour
              1.1
            when /audio/
              # Audio streams: ~128-320 kbps
              # Assume average 256 kbps = 0.032 MB/s = 0.115 GB/hour
              0.115
            else
              # Generic video estimate
              2.0
            end
          end

          def estimated_monthly_storage_gb
            return 0 unless has_retention_configured?

            hours_stored = [data_retention_in_hours, 24 * 30].min # Max 30 days for monthly calc
            estimated_storage_gb_per_hour * hours_stored
          end

          def estimated_monthly_cost_usd
            # Assume continuous streaming for cost estimation
            monthly_ingestion_gb = estimated_storage_gb_per_hour * 24 * 30 # 30 days
            monthly_storage_gb = estimated_monthly_storage_gb

            total_cost = (monthly_ingestion_gb * INGESTION_COST_PER_GB) +
                         (monthly_storage_gb * STORAGE_COST_PER_GB_MONTH)
            total_cost.round(2)
          end

          def streaming_endpoint_format
            "https://{random-id}.kinesisvideo.{region}.amazonaws.com"
          end

          def webrtc_signaling_endpoint_format
            "https://{random-id}.kinesisvideo.{region}.amazonaws.com"
          end
        end
      end
    end
  end
end
