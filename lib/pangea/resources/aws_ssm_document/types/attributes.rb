# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        class SsmDocumentAttributes < Dry::Struct
          DOCUMENT_TYPES = %w[Command Policy Automation Session Package ApplicationConfiguration ApplicationConfigurationSchema DeploymentStrategy ChangeCalendar Composite ProblemAnalysis ProblemAnalysisTemplate CloudFormation ConformancePackTemplate QuickSetup].freeze

          attribute :name, Resources::Types::String
          attribute :document_type, Resources::Types::String.enum(*DOCUMENT_TYPES)
          attribute :content, Resources::Types::String
          attribute :document_format, Resources::Types::String.enum('YAML', 'JSON').default('JSON')
          attribute :target_type, Resources::Types::String.optional
          attribute :schema_version, Resources::Types::String.optional
          attribute :version_name, Resources::Types::String.optional
          attribute :permissions, Resources::Types::Hash.default({ type: 'Private' })
          attribute :requires, Resources::Types::Array.of(Resources::Types::Hash).default([].freeze)
          attribute :attachments_source, Resources::Types::Array.of(Resources::Types::Hash).default([].freeze)
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          def self.new(attributes = {})
            attrs = super(attributes)
            validate_content(attrs)
            validate_name(attrs)
            validate_target_type(attrs) if attrs.document_type == 'Command'
            validate_schema_version(attrs) if attrs.schema_version
            validate_permissions(attrs) if attrs.permissions[:type] == 'Share'
            validate_version_name(attrs) if attrs.version_name
            attrs
          end

          def self.validate_content(attrs)
            attrs.document_format == 'JSON' ? JSON.parse(attrs.content) : YAML.safe_load(attrs.content)
          rescue JSON::ParserError, Psych::SyntaxError => e
            raise Dry::Struct::Error, "Invalid #{attrs.document_format} content: #{e.message}"
          end

          def self.validate_name(attrs)
            raise Dry::Struct::Error, 'Document name must be 3-128 characters and contain only letters, numbers, hyphens, underscores, and periods' unless attrs.name.match?(/\A[a-zA-Z0-9_\-\.]{3,128}\z/)
          end

          def self.validate_target_type(attrs)
            valid_targets = ['/AWS::EC2::Instance', '/AWS::IoT::Thing', '/AWS::SSM::ManagedInstance']
            raise Dry::Struct::Error, "Invalid target_type for Command document. Must be one of: #{valid_targets.join(', ')}" if attrs.target_type && !valid_targets.include?(attrs.target_type)
          end

          def self.validate_schema_version(attrs)
            raise Dry::Struct::Error, "Schema version must be in format 'major.minor'" unless attrs.schema_version.match?(/\A\d+\.\d+\z/)
          end

          def self.validate_permissions(attrs)
            raise Dry::Struct::Error, 'account_ids is required when sharing document' unless attrs.permissions[:account_ids]&.any?
            attrs.permissions[:account_ids].each do |id|
              raise Dry::Struct::Error, "Invalid AWS account ID format: #{id}" unless id.match?(/\A\d{12}\z/)
            end
          end

          def self.validate_version_name(attrs)
            raise Dry::Struct::Error, 'Version name must be 1-128 characters' unless attrs.version_name.match?(/\A[a-zA-Z0-9_\-\.]{1,128}\z/)
          end

          def is_command_document? = document_type == 'Command'
          def is_automation_document? = document_type == 'Automation'
          def is_policy_document? = document_type == 'Policy'
          def is_session_document? = document_type == 'Session'
          def uses_json_format? = document_format == 'JSON'
          def uses_yaml_format? = document_format == 'YAML'
          def has_target_type? = !target_type.nil?
          def has_schema_version? = !schema_version.nil?
          def has_version_name? = !version_name.nil?
          def is_shared? = permissions[:type] == 'Share'
          def is_private? = permissions[:type] == 'Private'
          def has_dependencies? = requires.any?
          def has_attachments? = attachments_source.any?
          def shared_with_accounts = is_shared? ? (permissions[:account_ids] || []) : []
          def dependency_names = requires.map { |req| req[:name] }

          def parsed_content
            uses_json_format? ? JSON.parse(content) : YAML.safe_load(content)
          rescue StandardError
            nil
          end

          def document_steps
            parsed = parsed_content
            return [] unless parsed
            %w[Command Automation].include?(document_type) ? (parsed.dig('mainSteps') || []) : []
          end

          def estimated_execution_time
            steps = document_steps
            steps.empty? ? 'Unknown' : "~#{steps.count * 2} minutes"
          end
        end
      end
    end
  end
end
