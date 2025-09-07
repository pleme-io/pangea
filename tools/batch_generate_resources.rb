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


require 'yaml'
require 'json'
require_relative 'generate_resource'

# Batch resource generator for multiple AWS resources
class BatchResourceGenerator
  attr_reader :resources_file, :options

  def initialize(resources_file, options = {})
    @resources_file = resources_file
    @options = options
  end

  def generate_all!
    resources = load_resources
    total = resources.size
    
    puts "🚀 Generating #{total} AWS resources..."
    puts "-" * 50
    
    successful = 0
    failed = []
    
    resources.each_with_index do |resource_config, index|
      resource_name = resource_config.is_a?(Hash) ? resource_config['name'] : resource_config
      
      print "[#{index + 1}/#{total}] Generating #{resource_name}... "
      
      begin
        generator = ResourceGenerator.new(resource_name, options)
        generator.generate!
        successful += 1
        puts "✅"
      rescue => e
        failed << { resource: resource_name, error: e.message }
        puts "❌ (#{e.message})"
      end
    end
    
    puts "-" * 50
    puts "\n📊 Summary:"
    puts "   ✅ Successful: #{successful}"
    puts "   ❌ Failed: #{failed.size}"
    
    if failed.any?
      puts "\n❌ Failed resources:"
      failed.each do |failure|
        puts "   - #{failure[:resource]}: #{failure[:error]}"
      end
    end
  end

  private

  def load_resources
    case File.extname(resources_file)
    when '.yaml', '.yml'
      YAML.load_file(resources_file)['resources'] || []
    when '.json'
      JSON.parse(File.read(resources_file))['resources'] || []
    when '.txt'
      File.readlines(resources_file).map(&:strip).reject(&:empty?)
    else
      raise "Unsupported file format: #{File.extname(resources_file)}"
    end
  rescue => e
    raise "Failed to load resources file: #{e.message}"
  end
end

# Sample resource lists for common AWS services
SAMPLE_RESOURCES = {
  networking: %w[
    aws_eip
    aws_eip_association
    aws_network_interface
    aws_network_acl
    aws_network_acl_rule
    aws_route
    aws_route_table_association
    aws_vpc_endpoint
    aws_vpc_endpoint_service
    aws_vpc_peering_connection
    aws_vpc_peering_connection_accepter
    aws_vpn_connection
    aws_vpn_gateway
    aws_customer_gateway
  ],
  
  compute: %w[
    aws_ami
    aws_ami_copy
    aws_ami_from_instance
    aws_key_pair
    aws_placement_group
    aws_ec2_capacity_reservation
    aws_ec2_fleet
    aws_spot_instance_request
    aws_spot_fleet_request
    aws_ebs_volume
    aws_ebs_snapshot
    aws_volume_attachment
  ],
  
  containers: %w[
    aws_ecs_cluster
    aws_ecs_service
    aws_ecs_task_definition
    aws_ecs_capacity_provider
    aws_ecr_repository
    aws_ecr_repository_policy
    aws_ecr_lifecycle_policy
    aws_eks_cluster
    aws_eks_node_group
    aws_eks_fargate_profile
    aws_eks_addon
  ],
  
  serverless: %w[
    aws_lambda_function
    aws_lambda_layer_version
    aws_lambda_alias
    aws_lambda_event_source_mapping
    aws_lambda_permission
    aws_lambda_function_url
    aws_api_gateway_rest_api
    aws_api_gateway_resource
    aws_api_gateway_method
    aws_api_gateway_integration
    aws_api_gateway_deployment
    aws_api_gateway_stage
    aws_apigatewayv2_api
    aws_apigatewayv2_route
    aws_apigatewayv2_integration
    aws_apigatewayv2_stage
  ],
  
  database: %w[
    aws_db_subnet_group
    aws_db_parameter_group
    aws_db_option_group
    aws_db_snapshot
    aws_db_cluster_snapshot
    aws_rds_cluster
    aws_rds_cluster_instance
    aws_rds_cluster_parameter_group
    aws_db_proxy
    aws_db_proxy_target
    aws_db_proxy_endpoint
    aws_dynamodb_table
    aws_dynamodb_table_item
    aws_dynamodb_global_table
    aws_elasticache_cluster
    aws_elasticache_replication_group
    aws_elasticache_subnet_group
    aws_elasticache_parameter_group
  ],
  
  security: %w[
    aws_iam_user
    aws_iam_group
    aws_iam_policy
    aws_iam_instance_profile
    aws_iam_role_policy
    aws_iam_user_policy
    aws_iam_group_policy
    aws_iam_role_policy_attachment
    aws_iam_user_policy_attachment
    aws_iam_group_policy_attachment
    aws_kms_key
    aws_kms_alias
    aws_kms_grant
    aws_secretsmanager_secret
    aws_secretsmanager_secret_version
    aws_ssm_parameter
    aws_ssm_document
  ],
  
  monitoring: %w[
    aws_cloudwatch_dashboard
    aws_cloudwatch_log_group
    aws_cloudwatch_log_stream
    aws_cloudwatch_metric_stream
    aws_cloudwatch_event_rule
    aws_cloudwatch_event_target
    aws_sns_topic
    aws_sns_topic_subscription
    aws_sqs_queue
    aws_sqs_queue_policy
  ],
  
  storage: %w[
    aws_s3_bucket_policy
    aws_s3_bucket_acl
    aws_s3_bucket_cors_configuration
    aws_s3_bucket_website_configuration
    aws_s3_bucket_versioning
    aws_s3_bucket_lifecycle_configuration
    aws_s3_bucket_replication_configuration
    aws_s3_bucket_logging
    aws_s3_bucket_encryption
    aws_s3_bucket_public_access_block
    aws_s3_object
    aws_s3_object_copy
    aws_efs_file_system
    aws_efs_mount_target
    aws_efs_access_point
  ]
}

# CLI Interface
if __FILE__ == $0
  require 'optparse'
  
  options = {}
  
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: batch_generate_resources.rb [options]"
    
    opts.on("-f", "--file FILE", "Resource list file (YAML, JSON, or TXT)") do |file|
      options[:file] = file
    end
    
    opts.on("-c", "--category CATEGORY", "Generate resources for a category (#{SAMPLE_RESOURCES.keys.join(', ')})") do |category|
      options[:category] = category.to_sym
    end
    
    opts.on("-l", "--list", "List available categories and their resources") do
      options[:list] = true
    end
    
    opts.on("--force", "Overwrite existing files") do
      options[:force] = true
    end
    
    opts.on("-h", "--help", "Show this help message") do
      puts opts
      exit
    end
  end
  
  parser.parse!
  
  if options[:list]
    puts "📋 Available resource categories:\n\n"
    SAMPLE_RESOURCES.each do |category, resources|
      puts "#{category.to_s.capitalize} (#{resources.size} resources):"
      puts resources.map { |r| "  - #{r}" }.join("\n")
      puts
    end
    exit
  end
  
  if options[:category]
    # Generate sample file for category
    resources = SAMPLE_RESOURCES[options[:category]]
    if resources.nil?
      puts "❌ Unknown category: #{options[:category]}"
      puts "Available categories: #{SAMPLE_RESOURCES.keys.join(', ')}"
      exit 1
    end
    
    # Create temporary file
    require 'tempfile'
    file = Tempfile.new(['resources', '.yaml'])
    file.write({ 'resources' => resources }.to_yaml)
    file.close
    
    begin
      generator = BatchResourceGenerator.new(file.path, options)
      generator.generate_all!
    ensure
      file.unlink
    end
  elsif options[:file]
    unless File.exist?(options[:file])
      puts "❌ File not found: #{options[:file]}"
      exit 1
    end
    
    generator = BatchResourceGenerator.new(options[:file], options)
    generator.generate_all!
  else
    puts parser
    exit 1
  end
end