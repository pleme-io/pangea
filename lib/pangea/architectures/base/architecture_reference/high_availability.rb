# frozen_string_literal: true

module Pangea
  module Architectures
    module Base
      class ArchitectureReference
        # High availability assessment
        module HighAvailability
          def high_availability_score
            checks = [
              check_multi_az_deployment,
              check_auto_scaling_enabled,
              check_load_balancer_present,
              check_database_redundancy,
              check_backup_strategy
            ]
            (checks.count(true).to_f / checks.length * 100).round(2)
          end

          private

          def check_multi_az_deployment
            az_resources = all_resources.select { |r| r.respond_to?(:availability_zones) }
            return true if az_resources.empty?

            az_resources.any? { |r| r.availability_zones&.size.to_i > 1 }
          end

          def check_auto_scaling_enabled
            scalable_resources = all_resources.select { |r| r.respond_to?(:auto_scaling_enabled?) }
            return true if scalable_resources.empty?

            scalable_resources.any?(&:auto_scaling_enabled?)
          end

          def check_load_balancer_present
            all_resources.any? { |r| r.class.name.to_s.downcase.include?('load_balancer') }
          end

          def check_database_redundancy
            db_resources = all_resources.select { |r| r.class.name.to_s.downcase.include?('db') }
            return true if db_resources.empty?

            db_resources.all? { |r| r.respond_to?(:backup_enabled?) ? r.backup_enabled? : true }
          end

          def check_backup_strategy
            backup_resources = all_resources.select { |r| r.respond_to?(:backup_retention_days) }
            return true if backup_resources.empty?

            backup_resources.all? { |r| r.backup_retention_days.to_i > 0 }
          end
        end
      end
    end
  end
end
