#!/usr/bin/env ruby

require_relative 'discover_resources'

class ResourcePrioritizer
  PRIORITY_GROUPS = {
    critical: %w[
      aws_vpc aws_subnet aws_security_group aws_instance aws_internet_gateway
      aws_route_table aws_route aws_nat_gateway aws_eip aws_key_pair
    ],
    high: %w[
      aws_s3_bucket aws_iam_role aws_iam_policy aws_iam_user aws_db_instance
      aws_rds_cluster aws_lambda_function aws_api_gateway_rest_api
      aws_cloudwatch_log_group aws_secretsmanager_secret
    ],
    medium: %w[
      aws_lb aws_lb_target_group aws_autoscaling_group aws_launch_template
      aws_ecs_cluster aws_ecs_service aws_cloudfront_distribution
      aws_route53_zone aws_route53_record aws_acm_certificate
    ],
    low: [] # Everything else
  }
  
  def self.categorize_resources
    all_resources = ResourceDiscoverer.discover_all_resources
    categorized = { critical: [], high: [], medium: [], low: [] }
    
    all_resources.each do |resource|
      priority = find_priority(resource[:name])
      categorized[priority] << resource
    end
    
    categorized
  end
  
  def self.find_priority(resource_name)
    PRIORITY_GROUPS.each do |priority, resources|
      return priority if resources.include?(resource_name)
    end
    :low
  end
  
  def self.generate_prioritized_list
    categorized = categorize_resources
    
    puts "Resource Testing Priority Groups:"
    categorized.each do |priority, resources|
      puts "\n#{priority.to_s.upcase} (#{resources.length}):"
      resources.each { |r| puts "  - #{r[:name]}" }
    end
    
    categorized
  end
end

if __FILE__ == $0
  ResourcePrioritizer.generate_prioritized_list
end