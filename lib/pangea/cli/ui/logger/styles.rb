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
      class Logger
        # Style configuration for log levels
        module Styles
          # Style configuration for log levels
          LOG_STYLES = {
            info:    { symbol: "ℹ",  label: "info",    color: :bright_blue,   levelpad: 1 },
            success: { symbol: "✓", label: "success", color: :bright_green,  levelpad: 0 },
            error:   { symbol: "✗", label: "error",   color: :bright_red,    levelpad: 1 },
            warn:    { symbol: "⚠",  label: "warning", color: :bright_yellow, levelpad: 0 },
            debug:   { symbol: "•", label: "debug",   color: :bright_black,  levelpad: 1 }
          }.freeze

          # Action symbols and colors mapping
          ACTION_STYLES = {
            create:  { symbol: "◉", color: :bright_green },
            update:  { symbol: "◎", color: :bright_yellow },
            delete:  { symbol: "◯", color: :bright_red },
            replace: { symbol: "⧗", color: :bright_magenta },
            import:  { symbol: "⬇", color: :bright_blue },
            refresh: { symbol: "↻", color: :bright_cyan },
            default: { symbol: "●", color: :white }
          }.freeze

          # Status indicators mapping
          STATUS_INDICATORS = {
            success: " ✓",
            error:   " ✗",
            warning: " ⚠",
            pending: " ⧖"
          }.freeze

          # Template action icons
          TEMPLATE_ICONS = {
            compiling:  "⚙️",
            compiled:   "✅",
            failed:     "❌",
            validating: "🔍",
            validated:  "✅",
            default:    "📄"
          }.freeze
        end
      end
    end
  end
end
