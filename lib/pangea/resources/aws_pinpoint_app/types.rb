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


require "dry-struct"
require "pangea/types"

module Pangea
  module Resources
    module AwsPinpointApp
      module Types
        # Campaign hook for Lambda integration
        class CampaignHook < Dry::Struct
          attribute :lambda_function_name?, Pangea::Types::String
          attribute :mode?, Pangea::Types::String.enum("DELIVERY", "FILTER")
          attribute :web_url?, Pangea::Types::String
        end

        # Quiet time configuration
        class QuietTime < Dry::Struct
          attribute :end?, Pangea::Types::String  # HH:MM format
          attribute :start?, Pangea::Types::String  # HH:MM format
        end

        # Application limits
        class Limits < Dry::Struct
          attribute :daily?, Pangea::Types::Integer
          attribute :maximum_duration?, Pangea::Types::Integer
          attribute :messages_per_second?, Pangea::Types::Integer
          attribute :total?, Pangea::Types::Integer
        end

        # Main attributes for Pinpoint app
        class Attributes < Dry::Struct
          # Required attributes
          attribute :name, Pangea::Types::String
          
          # Optional attributes
          attribute :name_prefix?, Pangea::Types::String
          attribute :campaign_hook?, CampaignHook
          attribute :limits?, Limits
          attribute :quiet_time?, QuietTime
          attribute :tags?, Pangea::Types::Hash.map(Pangea::Types::String, Pangea::Types::String)

          def self.from_dynamic(d)
            d = Pangea::Types::Hash[d]
            
            # Validate quiet time format
            if d[:quiet_time]
              qt = d[:quiet_time]
              if qt[:start] && !qt[:start].match?(/^\d{2}:\d{2}$/)
                raise ArgumentError, "quiet_time.start must be in HH:MM format"
              end
              if qt[:end] && !qt[:end].match?(/^\d{2}:\d{2}$/)
                raise ArgumentError, "quiet_time.end must be in HH:MM format"
              end
            end

            new(
              name: d.fetch(:name),
              name_prefix: d[:name_prefix],
              campaign_hook: d[:campaign_hook] ? CampaignHook.from_dynamic(d[:campaign_hook]) : nil,
              limits: d[:limits] ? Limits.from_dynamic(d[:limits]) : nil,
              quiet_time: d[:quiet_time] ? QuietTime.from_dynamic(d[:quiet_time]) : nil,
              tags: d[:tags]
            )
          end
        end

        # Reference for Pinpoint app resources
        class Reference < Dry::Struct
          attribute :application_id, Pangea::Types::String
          attribute :arn, Pangea::Types::String
          attribute :name, Pangea::Types::String
        end
      end
    end
  end
end