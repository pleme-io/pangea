# frozen_string_literal: true

module Pangea
  module Architectures
    module Base
      class ArchitectureReference
        # Security compliance checks
        module Security
          def security_compliance_score
            checks = [
              check_encryption_at_rest,
              check_encryption_in_transit,
              check_network_isolation,
              check_access_controls,
              check_monitoring_enabled
            ]
            (checks.count(true).to_f / checks.length * 100).round(2)
          end

          private

          def check_encryption_at_rest
            storage_resources = all_resources.select { |r| r.respond_to?(:encrypted?) }
            return true if storage_resources.empty?

            storage_resources.all?(&:encrypted?)
          end

          def check_encryption_in_transit
            network_resources = all_resources.select { |r| r.respond_to?(:tls_enabled?) }
            return true if network_resources.empty?

            network_resources.all?(&:tls_enabled?)
          end

          def check_network_isolation
            vpc_resources = all_resources.select { |r| r.respond_to?(:vpc_id) }
            return true if vpc_resources.empty?

            vpc_ids = vpc_resources.map(&:vpc_id).compact.uniq
            vpc_ids.size <= 1
          end

          def check_access_controls
            iam_resources = all_resources.select { |r| r.respond_to?(:iam_policies) }
            return true if iam_resources.empty?

            iam_resources.all? { |r| r.iam_policies&.any? }
          end

          def check_monitoring_enabled
            monitorable_resources = all_resources.select { |r| r.respond_to?(:monitoring_enabled?) }
            return true if monitorable_resources.empty?

            monitorable_resources.all?(&:monitoring_enabled?)
          end
        end
      end
    end
  end
end
