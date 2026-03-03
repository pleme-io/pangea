# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  class Agent
    # Private helper methods for the Agent class
    module Helpers
      private

      def sanitize_backend_config(namespace)
        config = namespace.to_terraform_backend
        config[:s3][:kms_key_id] = '***' if config[:s3]&.dig(:kms_key_id)
        config
      end

      def parse_function_name(function_name)
        match = function_name.match(/^aws_(\w+)_(\w+)$/)
        return nil unless match

        [match[1], match[2]]
      end

      def error_response(message)
        { error: true, message: message }
      end
    end
  end
end
