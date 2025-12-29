# frozen_string_literal: true

module Pangea
  module Architectures
    module Base
      class ArchitectureReference
        # Performance assessment
        module Performance
          def performance_score
            checks = [
              check_caching_enabled,
              check_cdn_configured,
              check_database_optimization,
              check_compute_sizing,
              check_network_optimization
            ]
            (checks.count(true).to_f / checks.length * 100).round(2)
          end

          private

          def check_caching_enabled
            all_resources.any? { |r| r.class.name.to_s.downcase.include?('cache') }
          end

          def check_cdn_configured
            all_resources.any? { |r| r.class.name.to_s.downcase.include?('cloudfront') }
          end

          def check_database_optimization
            db_resources = all_resources.select { |r| r.class.name.to_s.downcase.include?('db') }
            return true if db_resources.empty?

            true
          end

          def check_compute_sizing
            compute_resources = all_resources.select { |r| r.respond_to?(:instance_type) }
            return true if compute_resources.empty?

            production_with_burstable = compute_resources.any? do |r|
              r.instance_type&.start_with?('t') && (architecture_attributes[:environment] == 'production')
            end

            !production_with_burstable
          end

          def check_network_optimization
            network_resources = all_resources.select { |r| r.respond_to?(:enhanced_networking) }
            return true if network_resources.empty?

            network_resources.all?(&:enhanced_networking?)
          end
        end
      end
    end
  end
end
