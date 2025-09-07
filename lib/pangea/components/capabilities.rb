# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Pangea
  module Components
    module Capabilities
      module HighAvailability
        def self.included(base)
          base.class_eval do
            option :high_availability, default: -> { false }
            option :availability_zones, default: -> { [] }
            
            validation :high_availability_zones do
              if high_availability && availability_zones.size < 2
                raise ValidationError, "High availability requires at least 2 availability zones"
              end
            end
          end
        end
        
        def apply_high_availability(resource_config)
          return resource_config unless high_availability
          
          case resource_config[:type]
          when :aws_rds_instance
            resource_config.merge(multi_az: true)
          when :aws_elasticache_replication_group
            resource_config.merge(automatic_failover_enabled: true)
          else
            resource_config
          end
        end
      end
      
      module Monitoring
        def self.included(base)
          base.class_eval do
            option :enable_monitoring, default: -> { true }
            option :monitoring_level, default: -> { :standard }
          end
        end
        
        def monitoring_config
          return {} unless enable_monitoring
          
          case monitoring_level
          when :basic
            { detailed_monitoring: false, log_retention: 7 }
          when :standard
            { detailed_monitoring: true, log_retention: 30 }
          when :enhanced
            { detailed_monitoring: true, log_retention: 90, custom_metrics: true }
          end
        end
      end
      
      module Security
        def self.included(base)
          base.class_eval do
            option :enable_encryption, default: -> { true }
            option :enable_logging, default: -> { true }
          end
        end
        
        def apply_security(resource_config)
          config = resource_config.dup
          
          if enable_encryption
            config[:encrypted] = true if config[:type] == :aws_ebs_volume
            config[:storage_encrypted] = true if config[:type] == :aws_db_instance
          end
          
          if enable_logging
            config[:logging_enabled] = true
          end
          
          config
        end
      end
    end
  end
end