# frozen_string_literal: true

module Pangea
  module Resources
    module AWS
      module Types
        module MediaLiveChannel
          # Helper methods for MediaLiveChannelAttributes
          module Helpers
            def single_pipeline?
              channel_class == 'SINGLE_PIPELINE'
            end

            def standard_channel?
              channel_class == 'STANDARD'
            end

            def has_redundancy?
              standard_channel? && reserved_instances.any?
            end

            def input_count
              input_attachments.size
            end

            def output_group_count
              encoder_settings[:output_groups].size
            end

            def destination_count
              destinations.size
            end

            def has_vpc_config?
              vpc.any?
            end

            def maintenance_scheduled?
              maintenance[:maintenance_day] && maintenance[:maintenance_start_time]
            end

            def schedule_actions_count
              schedule.size
            end

            def supports_hdr?
              input_specification[:codec] == 'HEVC'
            end

            def maximum_resolution
              input_specification[:resolution]
            end
          end
        end
      end
    end
  end
end
