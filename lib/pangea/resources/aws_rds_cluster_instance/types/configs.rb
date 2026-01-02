# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module AuroraInstanceConfigs
          def self.writer_instance(instance_class: 'db.r5.large')
            { instance_class: instance_class, promotion_tier: 0, performance_insights_enabled: true,
              monitoring_interval: 60, tags: { Role: 'writer', Tier: 'primary' } }
          end

          def self.reader_instance(instance_class: 'db.r5.large', tier: 1)
            { instance_class: instance_class, promotion_tier: tier, performance_insights_enabled: true,
              monitoring_interval: 30, tags: { Role: 'reader', Tier: "tier-#{tier}" } }
          end

          def self.development_instance
            { instance_class: 'db.t3.medium', promotion_tier: 0, performance_insights_enabled: false,
              monitoring_interval: 0, auto_minor_version_upgrade: true, tags: { Environment: 'development', CostOptimized: 'true' } }
          end

          def self.production_writer
            { instance_class: 'db.r5.2xlarge', promotion_tier: 0, performance_insights_enabled: true,
              performance_insights_retention_period: 93, monitoring_interval: 15,
              tags: { Environment: 'production', Role: 'writer', CriticalSystem: 'true' } }
          end

          def self.production_reader(tier: 1)
            { instance_class: 'db.r5.xlarge', promotion_tier: tier, performance_insights_enabled: true,
              performance_insights_retention_period: 31, monitoring_interval: 60,
              tags: { Environment: 'production', Role: 'reader', Tier: "tier-#{tier}" } }
          end

          def self.graviton_writer
            { instance_class: 'db.r6g.large', promotion_tier: 0, performance_insights_enabled: true,
              monitoring_interval: 60, tags: { Role: 'writer', Architecture: 'graviton2', CostOptimized: 'true' } }
          end

          def self.graviton_reader(tier: 1)
            { instance_class: 'db.r6g.large', promotion_tier: tier, performance_insights_enabled: true,
              monitoring_interval: 30, tags: { Role: 'reader', Architecture: 'graviton2', Tier: "tier-#{tier}", CostOptimized: 'true' } }
          end

          def self.multi_az_deployment
            {
              writer: writer_instance(instance_class: 'db.r5.large'),
              reader_az_b: reader_instance(instance_class: 'db.r5.large', tier: 1),
              reader_az_c: reader_instance(instance_class: 'db.r5.large', tier: 2)
            }
          end
        end
      end
    end
  end
end
