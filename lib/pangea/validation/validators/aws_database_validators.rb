# frozen_string_literal: true
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

require 'pangea/validation/base_validator'

module Pangea
  module Validation
    module Validators
      # RDS Instance Validator
      DbInstanceValidator = BaseValidator.for_resource(:aws_db_instance) do
        params do
          required(:identifier).filled(:string)
          required(:allocated_storage).filled(:integer)
          required(:storage_type).filled(:string)
          required(:engine).filled(:string)
          required(:engine_version).filled(:string)
          required(:instance_class).filled(:string)
          required(:db_name).filled(:string)
          required(:username).filled(:string)
          required(:password).filled(:string)
          optional(:port).filled(:integer)
          optional(:multi_az).filled(:bool)
          optional(:publicly_accessible).filled(:bool)
          optional(:backup_retention_period).filled(:integer)
          optional(:backup_window).filled(:string)
          optional(:maintenance_window).filled(:string)
          optional(:tags).hash
        end
        
        rule(:identifier) do
          unless value.match?(/^[a-z][a-z0-9-]*$/) && value.length <= 63
            key.failure('must start with a letter, contain only lowercase letters, numbers, and hyphens, max 63 chars')
          end
        end
        
        rule(:allocated_storage) do
          if value < 20 || value > 65536
            key.failure('must be between 20 and 65536 GB')
          end
        end
        
        rule(:storage_type) do
          unless %w[gp2 gp3 io1 standard].include?(value)
            key.failure('must be one of: gp2, gp3, io1, standard')
          end
        end
        
        rule(:engine) do
          valid_engines = %w[
            mysql postgres mariadb oracle-ee oracle-se2 oracle-se1 oracle-se 
            sqlserver-ee sqlserver-se sqlserver-ex sqlserver-web
          ]
          unless valid_engines.include?(value)
            key.failure('must be a valid RDS engine')
          end
        end
        
        rule(:instance_class) do
          unless value.match?(/^db\.[a-z0-9]+\.(micro|small|medium|large|xlarge|[0-9]+xlarge)$/)
            key.failure('must be a valid RDS instance class (e.g., db.t3.micro)')
          end
        end
        
        rule(:port) do
          key.failure('invalid port') unless valid_port?(value)
        end
        
        rule(:backup_retention_period) do
          if value < 0 || value > 35
            key.failure('must be between 0 and 35 days')
          end
        end
        
        rule(:backup_window) do
          unless value.match?(/^\d{2}:\d{2}-\d{2}:\d{2}$/)
            key.failure('must be in format HH:MM-HH:MM')
          end
        end
        
        rule(:maintenance_window) do
          unless value.match?(/^(sun|mon|tue|wed|thu|fri|sat):\d{2}:\d{2}-(sun|mon|tue|wed|thu|fri|sat):\d{2}:\d{2}$/i)
            key.failure('must be in format ddd:HH:MM-ddd:HH:MM')
          end
        end
      end
    end
  end
end