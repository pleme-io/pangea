# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module CLI
    module UI
      class OutputFormatter
        ICONS = {
          success: '✓', error: '✗', warning: '⚠', info: 'ℹ', pending: '⧖',
          create: '+', update: '~', delete: '-', replace: '±', import: '⬇', refresh: '↻',
          template: '📄', resource: '🏗️', provider: '☁️', backend: '🔧', namespace: '🏷️',
          workspace: '📁', config: '⚙️', summary: '📊', plan: '📋', output: '📤',
          state: '📈', diff: '🔄', security: '🔒', network: '🌐', database: '🗄️',
          compute: '💻', storage: '💾', compiling: '⚙️', compiled: '✅', failed: '❌',
          validating: '🔍', validated: '✅', applying: '🚀', destroying: '💥', initializing: '🔧'
        }.freeze

        COLORS = {
          success: :green, error: :red, warning: :yellow, info: :blue, pending: :cyan,
          create: :green, update: :yellow, delete: :red, replace: :magenta,
          primary: :cyan, secondary: :bright_cyan, muted: :bright_black, highlight: :bright_white,
          resource_type: :cyan, resource_name: :bright_white, attribute_key: :white, attribute_value: :bright_black
        }.freeze
      end
    end
  end
end
