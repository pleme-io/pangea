#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo script to showcase Pangea's beautiful CLI features

require 'bundler/setup'
require 'pangea'
require 'pangea/cli/ui/progress'
require 'pangea/cli/ui/diff'
require 'pangea/cli/ui/visualizer'
require 'pangea/cli/ui/logger'

# Create UI components
logger = Pangea::CLI::UI::Logger.new
progress = Pangea::CLI::UI::Progress.new
diff = Pangea::CLI::UI::Diff.new
visualizer = Pangea::CLI::UI::Visualizer.new

# Demo: Beautiful logging
logger.section "Beautiful Logging Demo"
logger.info "This is an info message"
logger.success "This is a success message"
logger.warn "This is a warning message"
logger.error "This is an error message"
logger.debug "This is a debug message (visible with DEBUG=1)"

# Demo: Resource actions
logger.section "Resource Actions"
logger.resource_action(:create, "aws_instance", "web_server")
logger.resource_action(:update, "aws_s3_bucket", "assets")
logger.resource_action(:delete, "aws_lambda_function", "old_processor")
logger.resource_action(:replace, "aws_rds_instance", "database")

# Demo: Progress indicators
logger.section "Progress Indicators"

# Single progress bar
progress.single("Processing files", total: 5) do |bar|
  5.times do |i|
    sleep(0.5)
    bar.log("Processing file_#{i}.rb")
    bar.advance
  end
end

# Multi-bar progress
progress.multi("Deploying resources") do |multi|
  instances = multi.register(:instances, "EC2 Instances", total: 3)
  databases = multi.register(:databases, "RDS Databases", total: 2)
  buckets = multi.register(:buckets, "S3 Buckets", total: 4)
  
  # Simulate parallel deployment
  9.times do |i|
    sleep(0.3)
    case i % 3
    when 0
      multi.advance(:instances) if instances.current < 3
    when 1
      multi.advance(:databases) if databases.current < 2
    when 2
      multi.advance(:buckets) if buckets.current < 4
    end
  end
end

# Stage-based progress
progress.stages("Initializing backend", stages: ["Checking", "Creating", "Configuring", "Verifying"]) do |prog|
  4.times do
    sleep(0.5)
    prog.next_stage
  end
end

# Demo: Terraform plan diff
logger.section "Terraform Plan Diff"

sample_plan = <<~PLAN
Terraform will perform the following actions:

  # aws_instance.web will be created
  + resource "aws_instance" "web" {
      + ami                          = "ami-0c55b159cbfafe1f0"
      + instance_type                = "t2.micro"
      + availability_zone            = (known after apply)
      + id                           = (known after apply)
      + public_ip                    = (known after apply)
      + tags                         = {
          + "Name" = "WebServer"
        }
    }

  # aws_s3_bucket.assets will be updated in-place
  ~ resource "aws_s3_bucket" "assets" {
      ~ versioning {
          ~ enabled = false -> true
        }
        tags = {
          "Environment" = "production"
        }
    }

  # aws_rds_instance.old_db will be destroyed
  - resource "aws_rds_instance" "old_db" {
      - allocated_storage = 20 -> null
      - engine           = "postgres" -> null
      - instance_class   = "db.t2.micro" -> null
    }

Plan: 1 to add, 1 to change, 1 to destroy.
PLAN

diff.terraform_plan(sample_plan)

# Demo: Resource visualization
logger.section "Resource Visualization"

# State tree
state_resources = [
  { type: "aws_instance", name: "web_server", status: :active, attributes: { id: "i-1234567890", size: "t2.micro" } },
  { type: "aws_instance", name: "app_server", status: :active, attributes: { id: "i-0987654321", size: "t2.small" } },
  { type: "aws_s3_bucket", name: "assets", status: :active, attributes: { id: "my-assets-bucket" } },
  { type: "aws_rds_cluster", name: "main", status: :pending, attributes: { id: "main-cluster" } }
]

visualizer.state_tree(state_resources)

# Statistics dashboard
stats = {
  total_resources: 15,
  namespaces: 3,
  last_updated: Time.now.strftime("%Y-%m-%d %H:%M"),
  by_type: {
    "aws_instance" => 5,
    "aws_s3_bucket" => 3,
    "aws_rds_cluster" => 2,
    "aws_lambda_function" => 3,
    "aws_iam_role" => 2
  },
  by_provider: {
    "AWS" => 12,
    "Google Cloud" => 3
  }
}

visualizer.statistics_dashboard(stats)

# Plan impact
plan_data = {
  create: ["aws_instance.new_web", "aws_s3_bucket.backup"],
  update: ["aws_instance.app", "aws_rds_cluster.main"],
  destroy: ["aws_instance.old_web"],
  details: {
    create: [
      { type: "aws_instance", name: "new_web", reason: "Scaling up web tier" },
      { type: "aws_s3_bucket", name: "backup", reason: "Adding backup storage" }
    ],
    update: [
      { type: "aws_instance", name: "app", reason: "Updating instance type" },
      { type: "aws_rds_cluster", name: "main", reason: "Enabling encryption" }
    ],
    destroy: [
      { type: "aws_instance", name: "old_web", reason: "Replaced by new_web" }
    ]
  }
}

visualizer.plan_impact(plan_data)

# Demo complete
logger.section "Demo Complete"
logger.success "All UI components demonstrated successfully!"
logger.info "Run 'pangea --help' to see available commands"