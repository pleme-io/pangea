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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_ssm_patch_baseline/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Systems Manager Patch Baseline with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] SSM patch baseline attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ssm_patch_baseline(name, attributes = {})
        # Validate attributes using dry-struct
        baseline_attrs = Types::SsmPatchBaselineAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ssm_patch_baseline, name) do
          patch_baseline_name baseline_attrs.name
          operating_system baseline_attrs.operating_system

          # Description
          if baseline_attrs.description
            description baseline_attrs.description
          end

          # Approved patches
          if baseline_attrs.has_approved_patches?
            approved_patches baseline_attrs.approved_patches
          end

          # Rejected patches
          if baseline_attrs.has_rejected_patches?
            rejected_patches baseline_attrs.rejected_patches
          end

          # Compliance level and settings
          approved_patches_compliance_level baseline_attrs.approved_patches_compliance_level
          approved_patches_enable_non_security baseline_attrs.approved_patches_enable_non_security
          rejected_patches_action baseline_attrs.rejected_patches_action

          # Global filters
          baseline_attrs.global_filter.each do |filter|
            global_filter do
              key filter[:key]
              values filter[:values]
            end
          end

          # Approval rules
          baseline_attrs.approval_rule.each do |rule|
            approval_rule do
              approve_after_days rule[:approve_after_days] if rule[:approve_after_days]
              approve_until_date rule[:approve_until_date] if rule[:approve_until_date]
              compliance_level rule[:compliance_level] if rule[:compliance_level]
              enable_non_security rule[:enable_non_security] if rule[:enable_non_security]
              
              rule[:patch_filter].each do |filter|
                patch_filter do
                  key filter[:key]
                  values filter[:values]
                end
              end
            end
          end

          # Source configurations
          baseline_attrs.source.each do |source_config|
            source do
              source_name source_config[:name]
              products source_config[:products]
              configuration source_config[:configuration]
            end
          end

          # Apply tags if present
          if baseline_attrs.tags.any?
            tags do
              baseline_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_ssm_patch_baseline',
          name: name,
          resource_attributes: baseline_attrs.to_h,
          outputs: {
            id: "${aws_ssm_patch_baseline.#{name}.id}",
            name: "${aws_ssm_patch_baseline.#{name}.name}",
            arn: "${aws_ssm_patch_baseline.#{name}.arn}",
            created_date: "${aws_ssm_patch_baseline.#{name}.created_date}",
            modified_date: "${aws_ssm_patch_baseline.#{name}.modified_date}",
            description: "${aws_ssm_patch_baseline.#{name}.description}",
            operating_system: "${aws_ssm_patch_baseline.#{name}.operating_system}",
            approved_patches: "${aws_ssm_patch_baseline.#{name}.approved_patches}",
            rejected_patches: "${aws_ssm_patch_baseline.#{name}.rejected_patches}",
            approved_patches_compliance_level: "${aws_ssm_patch_baseline.#{name}.approved_patches_compliance_level}",
            tags_all: "${aws_ssm_patch_baseline.#{name}.tags_all}"
          },
          computed_properties: {
            is_windows: baseline_attrs.is_windows?,
            is_amazon_linux: baseline_attrs.is_amazon_linux?,
            is_redhat_family: baseline_attrs.is_redhat_family?,
            is_debian_family: baseline_attrs.is_debian_family?,
            is_suse: baseline_attrs.is_suse?,
            is_macos: baseline_attrs.is_macos?,
            has_description: baseline_attrs.has_description?,
            has_approved_patches: baseline_attrs.has_approved_patches?,
            has_rejected_patches: baseline_attrs.has_rejected_patches?,
            has_global_filters: baseline_attrs.has_global_filters?,
            has_approval_rules: baseline_attrs.has_approval_rules?,
            has_custom_sources: baseline_attrs.has_custom_sources?,
            enables_non_security_patches: baseline_attrs.enables_non_security_patches?,
            blocks_rejected_patches: baseline_attrs.blocks_rejected_patches?,
            allows_rejected_as_dependency: baseline_attrs.allows_rejected_as_dependency?,
            compliance_level_priority: baseline_attrs.compliance_level_priority,
            total_patch_count: baseline_attrs.total_patch_count,
            filter_summary: baseline_attrs.filter_summary,
            approval_rule_summary: baseline_attrs.approval_rule_summary
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)