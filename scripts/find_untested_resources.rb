#!/usr/bin/env ruby
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


# Script to find resources with implementations but no tests
TESTED_RESOURCES = %w[
  aws_vpc
  aws_subnet  
  aws_security_group
  aws_instance
  aws_internet_gateway
  aws_route_table
  aws_nat_gateway
  aws_launch_template
  aws_autoscaling_group
  aws_lb_target_group
  aws_lb
  aws_s3_bucket
  aws_iam_role
  aws_db_instance
  aws_eip
].freeze

untested = []

Dir.glob('lib/pangea/resources/aws_*/resource.rb').each do |resource_file|
  resource_name = File.basename(File.dirname(resource_file))
  
  # Check if it has an actual implementation
  content = File.read(resource_file)
  next unless content.include?("def #{resource_name}(")
  
  # Skip if already tested
  next if TESTED_RESOURCES.include?(resource_name)
  
  # Check if test directory exists
  test_dir = "spec/resources/#{resource_name}"
  unless Dir.exist?(test_dir)
    untested << resource_name
  end
end

puts "Found #{untested.length} untested resources with implementations:"
puts

# Group by service
grouped = untested.group_by { |r| r.split('_')[1] }

# Priority services (most commonly used)
priority_services = %w[
  iam
  kms
  route53
  cloudwatch
  lambda
  sns
  sqs
  rds
  elasticache
  ecs
  eks
  cloudfront
  api
]

puts "=== HIGH PRIORITY RESOURCES (Core Services) ==="
high_priority = []
priority_services.each do |service|
  if grouped[service]
    grouped[service].each do |resource|
      high_priority << resource
      puts "- #{resource}"
    end
  end
end

puts "\n=== MEDIUM PRIORITY RESOURCES (Supporting Services) ==="
medium_priority = []
%w[dynamodb s3 ecr elb autoscaling codebuild codedeploy].each do |service|
  if grouped[service] && !priority_services.include?(service)
    grouped[service].each do |resource|
      medium_priority << resource
      puts "- #{resource}"
    end
  end
end

puts "\n=== OTHER RESOURCES ==="
other = untested - high_priority - medium_priority
other.sort.each { |r| puts "- #{r}" }

puts "\n=== SUMMARY ==="
puts "High Priority: #{high_priority.length}"
puts "Medium Priority: #{medium_priority.length}"
puts "Other: #{other.length}"
puts "Total Untested: #{untested.length}"

# Export first batch of high priority tasks
File.write('untested_resources.json', {
  high_priority: high_priority.take(20),
  medium_priority: medium_priority.take(10),
  total_untested: untested.length
}.to_json)