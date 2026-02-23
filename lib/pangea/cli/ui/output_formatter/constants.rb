# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'boreal'

module Pangea
  module CLI
    module UI
      class OutputFormatter
        ICONS = Boreal::Theme::ICONS

        COLORS = {
          success: :success, error: :error, warning: :warning, info: :info, pending: :pending,
          create: :create, update: :update, delete: :delete, replace: :replace,
          primary: :primary, secondary: :secondary, muted: :muted, highlight: :bright,
          resource_type: :primary, resource_name: :bright, attribute_key: :text, attribute_value: :muted
        }.freeze
      end
    end
  end
end
