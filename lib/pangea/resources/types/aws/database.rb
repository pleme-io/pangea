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

require_relative 'core'

module Pangea
  module Resources
    module Types
      # RDS engine types
      RdsEngine = String.enum(
        'mysql', 'postgres', 'mariadb', 'oracle-ee', 'oracle-se2',
        'oracle-se1', 'oracle-se', 'sqlserver-ee', 'sqlserver-se',
        'sqlserver-ex', 'sqlserver-web', 'aurora-mysql', 'aurora-postgresql'
      )

      # RDS instance classes
      RdsInstanceClass = String.enum(
        'db.t3.micro', 'db.t3.small', 'db.t3.medium', 'db.t3.large', 'db.t3.xlarge', 'db.t3.2xlarge',
        'db.t4g.micro', 'db.t4g.small', 'db.t4g.medium', 'db.t4g.large', 'db.t4g.xlarge', 'db.t4g.2xlarge',
        'db.m5.large', 'db.m5.xlarge', 'db.m5.2xlarge', 'db.m5.4xlarge', 'db.m5.8xlarge', 'db.m5.12xlarge', 'db.m5.16xlarge', 'db.m5.24xlarge',
        'db.r5.large', 'db.r5.xlarge', 'db.r5.2xlarge', 'db.r5.4xlarge', 'db.r5.8xlarge', 'db.r5.12xlarge', 'db.r5.16xlarge', 'db.r5.24xlarge'
      )
    end
  end
end
