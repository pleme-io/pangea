# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # GuardDuty Detector attributes with validation
        class GuardDutyDetectorAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :enable, Resources::Types::Bool.default(true)
          attribute :finding_publishing_frequency, Resources::Types::GuardDutyFindingPublishingFrequency.default('SIX_HOURS')
          
          # Data source configurations
          attribute :datasources, Hash.schema(
            s3_logs?: Hash.schema(
              enable: Resources::Types::Bool
            ).optional,
            kubernetes?: Hash.schema(
              audit_logs: Hash.schema(
                enable: Resources::Types::Bool
              )
            ).optional,
            malware_protection?: Hash.schema(
              scan_ec2_instance_with_findings: Hash.schema(
                ebs_volumes: Hash.schema(
                  enable: Resources::Types::Bool
                )
              )
            ).optional
          ).default({}.freeze)
          
          attribute :tags, Resources::Types::AwsTags
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # If detector is disabled, finding publishing frequency should be considered
            if attrs[:enable] == false && attrs[:finding_publishing_frequency]
              # This is still valid, just note that frequency won't matter when disabled
            end
            
            super(attrs)
          end
          
          # Computed properties
          def has_s3_protection?
            datasources.dig(:s3_logs, :enable) == true
          end
          
          def has_kubernetes_protection?
            datasources.dig(:kubernetes, :audit_logs, :enable) == true
          end
          
          def has_malware_protection?
            datasources.dig(:malware_protection, :scan_ec2_instance_with_findings, :ebs_volumes, :enable) == true
          end
          
          def enabled_datasources
            sources = []
            sources << 'S3 Logs' if has_s3_protection?
            sources << 'Kubernetes Audit Logs' if has_kubernetes_protection?
            sources << 'Malware Protection' if has_malware_protection?
            sources
          end
          
          def comprehensive_protection?
            has_s3_protection? && has_kubernetes_protection? && has_malware_protection?
          end
        end
      end
    end
  end
end