# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        class GlobalClusterBackupConfiguration < Dry::Struct
          attribute :backup_retention_period, Resources::Types::Integer.default(7).constrained(gteq: 7, lteq: 35)
          attribute :preferred_backup_window, Resources::Types::String.optional
          attribute :copy_tags_to_snapshot, Resources::Types::Bool.default(true)

          def self.new(attributes = {})
            attrs = super(attributes)
            raise Dry::Struct::Error, "preferred_backup_window must be in format 'hh24:mi-hh24:mi' (UTC)" if attrs.preferred_backup_window && !valid_backup_window?(attrs.preferred_backup_window)
            attrs
          end

          def self.valid_backup_window?(window)
            return false unless window.match?(/^\d{2}:\d{2}-\d{2}:\d{2}$/)
            start_time, end_time = window.split('-')
            start_hour, start_min = start_time.split(':').map(&:to_i)
            end_hour, end_min = end_time.split(':').map(&:to_i)
            return false if start_hour > 23 || start_min > 59 || end_hour > 23 || end_min > 59
            start_minutes = start_hour * 60 + start_min
            end_minutes = end_hour * 60 + end_min
            end_minutes += 24 * 60 if end_minutes <= start_minutes
            (end_minutes - start_minutes) >= 30
          end

          def spans_midnight?
            return false unless preferred_backup_window
            start_time, end_time = preferred_backup_window.split('-')
            end_time.split(':').first.to_i <= start_time.split(':').first.to_i
          end

          def window_duration_minutes
            return nil unless preferred_backup_window
            start_time, end_time = preferred_backup_window.split('-')
            start_hour, start_min = start_time.split(':').map(&:to_i)
            end_hour, end_min = end_time.split(':').map(&:to_i)
            start_minutes = start_hour * 60 + start_min
            end_minutes = end_hour * 60 + end_min
            end_minutes += 24 * 60 if end_minutes <= start_minutes
            end_minutes - start_minutes
          end
        end
      end
    end
  end
end
