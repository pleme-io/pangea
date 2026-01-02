# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Domain validation methods for Route53 Zone attributes
        module Route53ZoneValidation
          def valid_domain_name?
            # Basic domain name validation
            return false if name.nil? || name.empty?

            # Cannot start or end with dot
            return false if name.start_with?('.') || name.end_with?('.')

            # Split into labels and validate each
            labels = name.split('.')
            return false if labels.empty?

            labels.all? { |label| valid_label?(label) }
          end

          def valid_label?(label)
            # Each label must be 1-63 characters
            return false if label.length < 1 || label.length > 63

            # Must start and end with alphanumeric
            return false unless label.match?(/\A[a-zA-Z0-9].*[a-zA-Z0-9]\z/) || label.length == 1

            # Can contain hyphens but not start or end with them
            return false if label.start_with?('-') || label.end_with?('-')

            # Only alphanumeric and hyphens allowed
            label.match?(/\A[a-zA-Z0-9\-]+\z/)
          end
        end
      end
    end
  end
end
