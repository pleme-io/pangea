# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'group_classification'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS IAM Group resources
        class IamGroupAttributes < Dry::Struct
          include GroupClassification

          transform_keys(&:to_sym)

          # Group name (required)
          attribute :name, Resources::Types::String

          # Path for the group (default: "/")
          attribute :path, Resources::Types::String.default("/")

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            # Validate group name meets IAM requirements
            unless attrs.name.match?(/\A[a-zA-Z0-9+=,.@_-]+\z/)
              raise Dry::Struct::Error, "Group name must contain only alphanumeric characters and +=,.@_-"
            end

            if attrs.name.length > 128
              raise Dry::Struct::Error, "Group name cannot exceed 128 characters"
            end

            # Validate path format
            unless attrs.path.match?(/\A\/[\w+=,.@\/-]*\z/)
              raise Dry::Struct::Error, "Path must start with '/' and contain only valid characters"
            end

            if attrs.path.length > 512
              raise Dry::Struct::Error, "Path cannot exceed 512 characters"
            end

            # Validate group security
            attrs.validate_group_security!

            attrs
          end

          # Check if group is in organizational path
          def organizational_path?
            path != "/" && path.include?("/")
          end

          # Extract organizational unit from path
          def organizational_unit
            return nil unless organizational_path?
            path.split('/').reject(&:empty?).first
          end

          # Generate group ARN
          def group_arn(account_id = "123456789012")
            "arn:aws:iam::#{account_id}:group#{path}#{name}"
          end

          # Validate group for security best practices
          def validate_group_security!
            warnings = []

            # Check for overly broad group names
            broad_names = ['users', 'all', 'everyone', 'default']
            if broad_names.any? { |broad| name.downcase.include?(broad) }
              warnings << "Group name '#{name}' is very broad - consider more specific grouping"
            end

            # Check for admin groups without organizational structure
            if administrative_group? && path == "/"
              warnings << "Administrative group '#{name}' should be in organized path structure"
            end

            # Check for environment groups without proper paths
            if environment_group? && !path.include?(extract_environment_from_name)
              warnings << "Environment group '#{name}' should be in environment-specific path"
            end

            # Log warnings but don't fail validation
            unless warnings.empty?
              puts "IAM Group Security Warnings for '#{name}':"
              warnings.each { |warning| puts "  - #{warning}" }
            end
          end
        end
      end
    end
  end
end
