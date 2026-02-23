# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module CLI
    module UI
      class Visualizer
        module Statistics
          def statistics_dashboard(stats)
            # Title
            title = " Infrastructure Statistics "
            box = TTY::Box.frame(
              width: @screen_width - 4,
              height: 20,
              padding: 1,
              title: { top_center: title },
              style: {
                fg: Boreal::Compat.pastel_sym(:primary),
                border: {
                  fg: Boreal::Compat.pastel_sym(:info)
                }
              }
            ) do
              lines = []

              # Summary stats
              lines << Boreal.bold("Summary")
              lines << "  Total Resources: #{stats[:total_resources]}"
              lines << "  Namespaces: #{stats[:namespaces]}"
              lines << "  Last Updated: #{stats[:last_updated]}"
              lines << ""

              # Resource breakdown
              lines << Boreal.bold("Resources by Type")
              stats[:by_type].each do |type, count|
                bar = progress_bar(count, stats[:total_resources], width: 20)
                lines << "  #{type.ljust(20)} #{bar} #{count}"
              end
              lines << ""

              # Provider breakdown
              lines << Boreal.bold("Resources by Provider")
              stats[:by_provider].each do |provider, count|
                percentage = (count.to_f / stats[:total_resources] * 100).round(1)
                lines << "  #{provider.ljust(20)} #{percentage}% (#{count})"
              end

              lines.join("\n")
            end

            puts box
          end
        end
      end
    end
  end
end
