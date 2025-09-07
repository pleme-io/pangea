#!/usr/bin/env ruby
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


require 'fileutils'

# List all generated resources from our batch
GENERATED_RESOURCES = [
  # Document Database Services (10 resources)
  'aws_docdb_cluster',
  'aws_docdb_cluster_instance', 
  'aws_docdb_cluster_parameter_group',
  'aws_docdb_cluster_snapshot',
  'aws_docdb_subnet_group',
  'aws_docdb_cluster_endpoint',
  'aws_docdb_global_cluster',
  'aws_docdb_event_subscription',
  'aws_docdb_certificate',
  'aws_docdb_cluster_backup',
  
  # Graph Database Services (8 resources)
  'aws_neptune_cluster',
  'aws_neptune_cluster_instance',
  'aws_neptune_cluster_parameter_group',
  'aws_neptune_cluster_snapshot',
  'aws_neptune_subnet_group',
  'aws_neptune_event_subscription',
  'aws_neptune_parameter_group',
  'aws_neptune_cluster_endpoint',
  
  # Time Series Database (7 resources)
  'aws_timestream_database',
  'aws_timestream_table',
  'aws_timestream_scheduled_query',
  'aws_timestream_batch_load_task',
  'aws_timestream_influx_db_instance',
  'aws_timestream_table_retention_properties',
  'aws_timestream_access_policy',
  
  # Memory Database Services (8 resources)
  'aws_memorydb_cluster',
  'aws_memorydb_parameter_group',
  'aws_memorydb_subnet_group',
  'aws_memorydb_user',
  'aws_memorydb_acl',
  'aws_memorydb_snapshot',
  'aws_memorydb_multi_region_cluster',
  'aws_memorydb_cluster_endpoint',
  
  # License Manager (7 resources)
  'aws_licensemanager_license_configuration',
  'aws_licensemanager_association',
  'aws_licensemanager_grant',
  'aws_licensemanager_grant_accepter',
  'aws_licensemanager_license_grant_accepter',
  'aws_licensemanager_token',
  'aws_licensemanager_report_generator',
  
  # Resource Access Manager (10 resources)
  'aws_ram_resource_share',
  'aws_ram_resource_association',
  'aws_ram_principal_association',
  'aws_ram_resource_share_accepter',
  'aws_ram_invitation_accepter',
  'aws_ram_sharing_with_organization',
  'aws_ram_permission',
  'aws_ram_permission_association',
  'aws_ram_resource_share_invitation',
  'aws_ram_managed_permission'
]

def update_aws_loader
  aws_loader_path = File.join(
    File.expand_path('../../lib/pangea/resources', __FILE__),
    'aws.rb'
  )
  
  puts "🔧 Updating AWS resources loader..."
  
  # Generate requires for all resources
  requires = GENERATED_RESOURCES.map do |resource|
    "require 'pangea/resources/#{resource}/resource'"
  end.join("\n")
  
  # Generate the new aws.rb content
  content = <<~RUBY
    # frozen_string_literal: true
    
    require 'pangea/resources/base'
    require 'pangea/resources/reference'
    
    # Load all AWS resource implementations
    #{requires}
    
    module Pangea
      module Resources
        # AWS resource functions - All #{GENERATED_RESOURCES.size} resources from database batch
        # Each resource file defines its method directly in the AWS module
        module AWS
          include Base
        end
      end
    end
  RUBY
  
  # Write the new loader
  File.write(aws_loader_path, content)
  puts "  ✅ Updated aws.rb with #{GENERATED_RESOURCES.size} resource includes"
  
  puts "\n📋 Resources included:"
  puts "   📊 Document Database: 10 resources"  
  puts "   🌐 Graph Database (Neptune): 8 resources"
  puts "   ⏰ Time Series Database: 7 resources"
  puts "   💾 Memory Database: 8 resources"
  puts "   🔑 License Manager: 7 resources"
  puts "   🤝 Resource Access Manager: 10 resources"
  puts "   =" * 40
  puts "   📈 Total: #{GENERATED_RESOURCES.size} AWS resources"
end

# This method is no longer needed since resources define methods directly
# def module_name(resource_name)
#   # Convert aws_docdb_cluster to AwsDocdbCluster  
#   parts = resource_name.split('_')
#   parts.map(&:capitalize).join
# end

if __FILE__ == $0
  update_aws_loader
  
  puts "\n🎉 AWS loader update complete!"
  puts "\n💡 Next steps:"
  puts "1. Test the loader by requiring 'pangea/resources/aws'"
  puts "2. Verify all resource functions are available"
  puts "3. Run any existing tests to ensure compatibility"
end
RUBY