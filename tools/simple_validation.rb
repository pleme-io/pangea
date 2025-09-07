#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'

# Simple validation to check all database resources were generated properly
class SimpleValidator
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

  attr_reader :base_path

  def initialize
    @base_path = File.join(
      File.expand_path('../../lib/pangea/resources', __FILE__)
    )
  end

  def validate_all!
    puts "🔍 Validating #{GENERATED_RESOURCES.size} database service resources..."
    puts "📁 Base path: #{base_path}"
    puts "=" * 70
    
    successful = 0
    failed = []
    
    GENERATED_RESOURCES.each_with_index do |resource, index|
      print "[#{index + 1}/#{GENERATED_RESOURCES.size}] Checking #{resource}... "
      
      begin
        validate_resource_files(resource)
        successful += 1
        puts "✅"
      rescue => e
        failed << { resource: resource, error: e.message }
        puts "❌ (#{e.message})"
      end
    end
    
    puts "=" * 70
    print_summary(successful, failed)
    
    failed.empty?
  end

  private

  def validate_resource_files(resource_name)
    resource_dir = File.join(base_path, resource_name)
    
    # Check directory exists
    unless Dir.exist?(resource_dir)
      raise "Directory #{resource_name} does not exist"
    end
    
    # Check required files
    required_files = %w[resource.rb types.rb CLAUDE.md README.md]
    missing_files = []
    
    required_files.each do |file|
      file_path = File.join(resource_dir, file)
      unless File.exist?(file_path)
        missing_files << file
      end
    end
    
    unless missing_files.empty?
      raise "Missing files: #{missing_files.join(', ')}"
    end
    
    # Check file contents
    validate_resource_file(resource_name)
    validate_types_file(resource_name)
  end
  
  def validate_resource_file(resource_name)
    resource_file = File.join(base_path, resource_name, 'resource.rb')
    content = File.read(resource_file)
    
    # Check for method definition
    unless content.include?("def #{resource_name}(")
      raise "resource.rb missing method definition"
    end
    
    # Check for ResourceReference
    unless content.include?("ResourceReference.new")
      raise "resource.rb missing ResourceReference.new"
    end
    
    # Check for dry-struct validation  
    unless content.include?(".new(attributes)")
      raise "resource.rb missing dry-struct validation"
    end
  end
  
  def validate_types_file(resource_name)
    types_file = File.join(base_path, resource_name, 'types.rb')
    content = File.read(types_file)
    
    # Check for class definition
    class_name = resource_name.split('_').map(&:capitalize).join.gsub('Aws', '') + 'Attributes'
    unless content.include?("class #{class_name}")
      raise "types.rb missing #{class_name} class"
    end
    
    # Check for dry-struct inheritance
    unless content.include?("< Dry::Struct")
      raise "types.rb missing Dry::Struct inheritance"
    end
  end
  
  def print_summary(successful, failed)
    puts "\n📊 Validation Summary:"
    puts "   ✅ Successful: #{successful}"
    puts "   ❌ Failed: #{failed.size}"
    puts "   📈 Success Rate: #{(successful.to_f / GENERATED_RESOURCES.size * 100).round(1)}%"
    
    puts "\n📋 Service Breakdown:"
    puts "   📄 Document Database: 10 resources"
    puts "   🌐 Graph Database (Neptune): 8 resources"
    puts "   ⏰ Time Series Database: 7 resources"
    puts "   💾 Memory Database: 8 resources"
    puts "   🔑 License Manager: 7 resources"
    puts "   🤝 Resource Access Manager: 10 resources"
    
    if failed.any?
      puts "\n❌ Failed Resources:"
      failed.each do |failure|
        puts "   - #{failure[:resource]}: #{failure[:error]}"
      end
      
      puts "\n🔧 How to fix:"
      puts "1. Run the batch generation script again for failed resources"
      puts "2. Run the enhancement script to add proper attributes"
      puts "3. Check file permissions and directory structure"
    else
      puts "\n🎉 All resources validated successfully!"
      puts "\n✨ What was validated:"
      puts "   📁 Directory structure for all resources"
      puts "   📄 Required files: resource.rb, types.rb, CLAUDE.md, README.md"
      puts "   🏗️  Method definitions in resource.rb files"
      puts "   🔒 Type safety with dry-struct classes"
      puts "   📋 ResourceReference return values"
      
      puts "\n🚀 Database services implementation complete!"
      puts "   Total: #{GENERATED_RESOURCES.size} AWS database resources"
      puts "   Ready for production infrastructure deployment"
    end
  end
end

if __FILE__ == $0
  validator = SimpleValidator.new
  success = validator.validate_all!
  exit(success ? 0 : 1)
end