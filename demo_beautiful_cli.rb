#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo script showcasing the beautiful Pangea CLI components
$LOAD_PATH.unshift File.expand_path('lib', __dir__)

require 'pangea/cli/ui/banner'
require 'pangea/cli/ui/logger'
require 'pangea/cli/ui/spinner'
require 'pangea/cli/ui/table'
require 'pangea/cli/ui/progress'

puts "\n🌍 Pangea CLI Beauty Demo"
puts "=" * 50

# Initialize UI components
banner = Pangea::CLI::UI::Banner.new
ui = Pangea::CLI::UI::Logger.new
progress = Pangea::CLI::UI::Progress.new

# 1. Welcome Banner
puts "\n1. Welcome Banner:"
puts banner.welcome

# 2. Command Header  
puts "\n2. Command Headers:"
banner.header('plan')
puts
banner.header('apply')
puts
banner.header('destroy')

# 3. Beautiful Logging
puts "\n3. Enhanced Logging:"
ui.section("Infrastructure Planning")
ui.info("Loading configuration...")
ui.success("Configuration loaded successfully")
ui.warn("Template version mismatch detected")
ui.error("Failed to connect to backend")

# 4. Resource Status Display
puts "\n4. Resource Status Display:"
ui.resource_status('aws_vpc', 'main', :create, :success, 'VPC created')
ui.resource_status('aws_subnet', 'public_a', :update, :warning, 'CIDR changed')
ui.resource_status('aws_instance', 'web', :delete, :error, 'Instance not found')
ui.resource_status('aws_rds_instance', 'db', :replace, :pending, 'Engine upgrade')

# 5. Template Processing
puts "\n5. Template Processing:"
ui.template_status('networking', :compiling)
sleep 1
ui.template_status('networking', :compiled, 2.3)
ui.template_status('compute', :validating)
ui.template_status('compute', :validated)
ui.template_status('database', :failed)

# 6. Spinners
puts "\n6. Spinner Demonstrations:"

# Basic spinner
spinner = Pangea::CLI::UI::Spinner.new("Processing templates")
spinner.start
sleep 2
spinner.success("Templates processed successfully")

# Terraform operation spinner
terraform_spinner = Pangea::CLI::UI::Spinner.terraform_operation(:plan)
terraform_spinner.start
sleep 1.5
terraform_spinner.success("Plan completed")

# Multi-stage spinner
puts "\nMulti-stage operation:"
Pangea::CLI::UI::Spinner.multi_stage([
  "Initializing backend",
  "Downloading modules", 
  "Generating plan"
]) do |spinner, stage|
  sleep 1
end

# 7. Tables
puts "\n7. Beautiful Tables:"

# Resource summary table
resources = [
  { type: 'aws_vpc', name: 'main', action: :create, status: :success, details: 'New VPC' },
  { type: 'aws_subnet', name: 'public_a', action: :update, status: :warning, details: 'CIDR changed' },
  { type: 'aws_instance', name: 'web', action: :replace, status: :pending, details: 'AMI update' },
  { type: 'aws_rds_instance', name: 'db', action: :delete, status: :error, details: 'Not found' }
]

puts Pangea::CLI::UI::Table.resource_summary(resources)

# Plan summary table
plan_data = [
  { type: 'aws_vpc', name: 'main', action: :create, reason: 'New resource' },
  { type: 'aws_subnet', name: 'public', action: :update, reason: 'Configuration changed' },
  { type: 'aws_instance', name: 'web', action: :replace, reason: 'AMI changed' }
]

puts "\nPlan Summary:"
puts Pangea::CLI::UI::Table.plan_summary(plan_data)

# Template summary
templates = [
  { name: 'networking', resource_count: 12, status: :compiled, duration: 2.3 },
  { name: 'compute', resource_count: 8, status: :compiled, duration: 1.8 },
  { name: 'database', resource_count: 5, status: :failed, duration: nil },
  { name: 'monitoring', resource_count: 15, status: :compiled, duration: 3.1 }
]

puts "\nTemplate Summary:"
puts Pangea::CLI::UI::Table.template_summary(templates)

# 8. Progress Bars
puts "\n8. Progress Indicators:"

# Single progress bar
progress.single("Deploying resources", total: 10) do |bar|
  10.times do |i|
    sleep 0.2
    bar.advance
    bar.log("  ✓ Created aws_instance.web_#{i}")
  end
end

# Multi-bar progress
puts "\nMulti-resource deployment:"
progress.multi("Creating infrastructure") do |multi|
  compute_bar = multi.register(:compute, "Compute resources", total: 5)
  network_bar = multi.register(:network, "Network resources", total: 3)
  storage_bar = multi.register(:storage, "Storage resources", total: 2)
  
  # Simulate parallel resource creation
  threads = []
  
  threads << Thread.new do
    5.times { sleep 0.3; multi.advance(:compute) }
  end
  
  threads << Thread.new do
    3.times { sleep 0.5; multi.advance(:network) }  
  end
  
  threads << Thread.new do
    2.times { sleep 0.8; multi.advance(:storage) }
  end
  
  threads.each(&:join)
end

# 9. Information Panels
puts "\n9. Information Panels:"

# Namespace info (simulated)
namespace_info = OpenStruct.new(
  name: 'production',
  state: OpenStruct.new(type: 's3', bucket: 'terraform-state-prod', region: 'us-east-1'),
  description: 'Production environment with encrypted state'
)
ui.namespace_info(namespace_info)

# Cost information
ui.cost_info(
  current: 450.25,
  estimated: 523.75,
  savings: -73.50
)

# Performance metrics
ui.performance_info({
  compilation_time: "3.2s",
  planning_time: "8.7s", 
  apply_time: "2m 34s",
  memory_usage: "156MB",
  terraform_version: "1.6.4"
})

# 10. Banners and Alerts
puts "\n10. Status Banners:"

puts banner.success("Infrastructure deployed successfully!", "All 25 resources created in 2m 34s")

puts banner.warning("Configuration drift detected", "5 resources have drifted from desired state")

puts banner.error("Deployment failed", "Invalid AMI ID specified", [
  "Check the AMI ID in your configuration",
  "Ensure the AMI exists in the target region",
  "Verify your AWS credentials have the required permissions"
])

# Operation summaries
puts "\n11. Operation Summaries:"

puts banner.operation_summary(:plan, { create: 12, update: 3, delete: 1, replace: 2 })
puts banner.operation_summary(:apply, { total: 18, duration: 156.7, estimated_cost: 287.50 })
puts banner.operation_summary(:destroy, { destroyed: 18, duration: 89.2 })

# 12. Celebrations
puts "\n12. Celebrations:"
ui.celebration("All tests passed!")
ui.celebration("Infrastructure deployed!", "🚀")

# 13. Warning Panel
puts "\n13. Warning Panels:"
ui.warning_panel("Important Security Notice", [
  "Default security groups allow all traffic",
  "Consider enabling encryption at rest",
  "Review IAM policies for least privilege"
])

puts "\n" + "=" * 50
puts "🎉 Demo completed! Pangea CLI is now beautiful! 🎉"