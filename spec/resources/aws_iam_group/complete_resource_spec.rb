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

require 'spec_helper'

# Load aws_iam_group resource and types for testing
require 'pangea/resources/aws_iam_group/resource'
require 'pangea/resources/aws_iam_group/types'

RSpec.describe "aws_iam_group resource function" do
  # Create a test class that includes the AWS module and mocks terraform-synthesizer
  let(:test_class) do
    Class.new do
      include Pangea::Resources::AWS
      
      # Mock the terraform-synthesizer resource method
      def resource(type, name)
        @resources ||= {}
        resource_data = { type: type, name: name, attributes: {} }
        
        yield if block_given?
        
        @resources["#{type}.#{name}"] = resource_data
        resource_data
      end
      
      # Method missing to capture terraform attributes
      def method_missing(method_name, *args, &block)
        # Don't capture certain methods that might interfere
        return super if [:expect, :be_a, :eq].include?(method_name)
        # For terraform-synthesizer attribute calls, just return the value
        args.first if args.any?
      end
      
      def respond_to_missing?(method_name, include_private = false)
        true
      end
    end
  end
  
  let(:test_instance) { test_class.new }
  
  describe "IamGroupAttributes validation" do
    it "accepts minimal configuration with required name" do
      attrs = Pangea::Resources::AWS::IamGroupAttributes.new({
        name: "developers"
      })
      
      expect(attrs.name).to eq("developers")
      expect(attrs.path).to eq("/")
    end
    
    it "accepts custom path" do
      attrs = Pangea::Resources::AWS::IamGroupAttributes.new({
        name: "developers",
        path: "/teams/engineering/"
      })
      
      expect(attrs.path).to eq("/teams/engineering/")
    end
    
    it "validates name format" do
      expect {
        Pangea::Resources::AWS::IamGroupAttributes.new({
          name: "invalid name with spaces"
        })
      }.to raise_error(Dry::Struct::Error, /must contain only alphanumeric characters/)
    end
    
    it "validates name length" do
      expect {
        Pangea::Resources::AWS::IamGroupAttributes.new({
          name: "a" * 129
        })
      }.to raise_error(Dry::Struct::Error, /cannot exceed 128 characters/)
    end
    
    it "validates path format" do
      expect {
        Pangea::Resources::AWS::IamGroupAttributes.new({
          name: "developers",
          path: "missing-leading-slash"
        })
      }.to raise_error(Dry::Struct::Error, /must start with '\'/)
    end
    
    it "validates path length" do
      expect {
        Pangea::Resources::AWS::IamGroupAttributes.new({
          name: "developers",
          path: "/" + "a" * 511 + "/"
        })
      }.to raise_error(Dry::Struct::Error, /cannot exceed 512 characters/)
    end
    
    it "detects administrative groups" do
      admin_names = ["platform-admins", "super-users", "root-group", "power-users"]
      
      admin_names.each do |name|
        attrs = Pangea::Resources::AWS::IamGroupAttributes.new({ name: name })
        expect(attrs.administrative_group?).to eq(true)
        expect(attrs.group_category).to eq(:administrative)
        expect(attrs.security_risk_level).to eq(:high)
      end
    end
    
    it "detects developer groups" do
      dev_names = ["frontend-developers", "backend-engineers", "mobile-programmers"]
      
      dev_names.each do |name|
        attrs = Pangea::Resources::AWS::IamGroupAttributes.new({ name: name })
        expect(attrs.developer_group?).to eq(true)
        expect(attrs.group_category).to eq(:developer)
        expect(attrs.security_risk_level).to eq(:medium)
      end
    end
    
    it "detects operations groups" do
      ops_names = ["platform-ops", "site-sre", "infrastructure-team"]
      
      ops_names.each do |name|
        attrs = Pangea::Resources::AWS::IamGroupAttributes.new({ name: name })
        expect(attrs.operations_group?).to eq(true)
        expect(attrs.group_category).to eq(:operations)
        expect(attrs.security_risk_level).to eq(:high)
      end
      
      # Special case: platform-engineers contains both "platform" and "engineer"
      # so it's categorized as developer (engineer takes precedence)
      attrs = Pangea::Resources::AWS::IamGroupAttributes.new({ name: "platform-engineers" })
      expect(attrs.operations_group?).to eq(true)  # Contains "platform"
      expect(attrs.developer_group?).to eq(true)   # Contains "engineer"
      expect(attrs.group_category).to eq(:developer)  # Developer takes precedence
      expect(attrs.security_risk_level).to eq(:medium)
    end
    
    it "detects readonly groups" do
      readonly_names = ["monitoring-readonly", "audit-viewers", "compliance-auditors"]
      
      readonly_names.each do |name|
        attrs = Pangea::Resources::AWS::IamGroupAttributes.new({ name: name })
        expect(attrs.readonly_group?).to eq(true)
        expect(attrs.group_category).to eq(:readonly)
        expect(attrs.security_risk_level).to eq(:low)
      end
    end
    
    it "detects department groups" do
      dept_names = ["engineering-standard", "finance-elevated", "marketing-team"]
      
      dept_names.each do |name|
        attrs = Pangea::Resources::AWS::IamGroupAttributes.new({ name: name })
        expect(attrs.department_group?).to eq(true)
        expect(attrs.extract_department_from_name).not_to be_nil
      end
    end
    
    it "detects environment groups" do
      env_names = ["production-deploy", "staging-admin", "development-users"]
      
      env_names.each do |name|
        attrs = Pangea::Resources::AWS::IamGroupAttributes.new({ name: name })
        expect(attrs.environment_group?).to eq(true)
        expect(attrs.extract_environment_from_name).not_to be_nil
      end
    end
    
    it "validates naming conventions" do
      good_names = ["engineering-developers", "production-deploy", "finance-readonly"]
      bad_names = ["developers", "-developers", "developers-", "dev"]
      
      good_names.each do |name|
        attrs = Pangea::Resources::AWS::IamGroupAttributes.new({ name: name })
        expect(attrs.follows_naming_convention?).to eq(true)
        expect(attrs.naming_convention_score).to be >= 40
      end
      
      bad_names.each do |name|
        attrs = Pangea::Resources::AWS::IamGroupAttributes.new({ name: name })
        expect(attrs.follows_naming_convention?).to eq(false)
      end
    end
    
    it "calculates naming convention score" do
      test_cases = {
        "engineering-developers-production" => 100,  # All criteria met
        "developers-production" => 80,               # Missing department
        "engineering-developers" => 60,              # Missing environment
        "developers" => 20,                          # Only length criteria
        "x" => 0                                     # No criteria met
      }
      
      test_cases.each do |name, expected_score|
        attrs = Pangea::Resources::AWS::IamGroupAttributes.new({ 
          name: name,
          path: "/teams/engineering/"
        })
        expect(attrs.naming_convention_score).to eq(expected_score)
      end
    end
    
    it "handles organizational paths" do
      attrs = Pangea::Resources::AWS::IamGroupAttributes.new({
        name: "developers",
        path: "/teams/engineering/backend/"
      })
      
      expect(attrs.organizational_path?).to eq(true)
      expect(attrs.organizational_unit).to eq("teams")
    end
    
    it "generates group ARN" do
      attrs = Pangea::Resources::AWS::IamGroupAttributes.new({
        name: "developers",
        path: "/teams/"
      })
      
      expect(attrs.group_arn).to eq("arn:aws:iam::123456789012:group/teams/developers")
      expect(attrs.group_arn("999888777666")).to eq("arn:aws:iam::999888777666:group/teams/developers")
    end
  end
  
  describe "aws_iam_group function behavior" do
    it "creates a resource reference with minimal attributes" do
      ref = test_instance.aws_iam_group(:test, {
        name: "developers"
      })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_iam_group')
      expect(ref.name).to eq(:test)
    end
    
    it "creates a group with custom path" do
      ref = test_instance.aws_iam_group(:eng_devs, {
        name: "engineering-developers",
        path: "/teams/engineering/"
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("engineering-developers")
      expect(attrs[:path]).to eq("/teams/engineering/")
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_iam_group(:test, {
        name: "test-group"
      })
      
      expected_outputs = [:id, :arn, :name, :path, :unique_id]
      
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_iam_group.test.")
      end
    end
    
    it "provides computed properties" do
      ref = test_instance.aws_iam_group(:admin_group, {
        name: "platform-admins",
        path: "/admins/"
      })
      
      expect(ref.administrative_group?).to eq(true)
      expect(ref.developer_group?).to eq(false)
      expect(ref.operations_group?).to eq(false)
      expect(ref.readonly_group?).to eq(false)
      expect(ref.group_category).to eq(:administrative)
      expect(ref.security_risk_level).to eq(:high)
      expect(ref.suggested_access_level).to eq(:full_admin)
      expect(ref.organizational_path?).to eq(true)
      expect(ref.organizational_unit).to eq("admins")
    end
  end
  
  describe "GroupPatterns module usage" do
    it "creates development team groups" do
      pattern = Pangea::Resources::AWS::GroupPatterns.development_team_group("frontend", "engineering")
      ref = test_instance.aws_iam_group(:frontend_team, pattern)
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("engineering-frontend-developers")
      expect(attrs[:path]).to eq("/teams/engineering/frontend/")
      expect(ref.developer_group?).to eq(true)
    end
    
    it "creates environment access groups" do
      pattern = Pangea::Resources::AWS::GroupPatterns.environment_access_group("production", "deploy")
      ref = test_instance.aws_iam_group(:prod_deployers, pattern)
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("production-deploy")
      expect(attrs[:path]).to eq("/environments/production/")
      expect(ref.environment_group?).to eq(true)
    end
    
    it "creates department groups" do
      pattern = Pangea::Resources::AWS::GroupPatterns.department_group("finance", "elevated")
      ref = test_instance.aws_iam_group(:finance_elevated, pattern)
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("finance-elevated")
      expect(attrs[:path]).to eq("/departments/finance/")
      expect(ref.department_group?).to eq(true)
    end
    
    it "creates admin groups" do
      pattern = Pangea::Resources::AWS::GroupPatterns.admin_group("security", "platform")
      ref = test_instance.aws_iam_group(:sec_admins, pattern)
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("platform-security-admins")
      expect(attrs[:path]).to eq("/admins/platform/")
      expect(ref.administrative_group?).to eq(true)
      expect(ref.security_risk_level).to eq(:high)
    end
    
    it "creates readonly groups" do
      pattern = Pangea::Resources::AWS::GroupPatterns.readonly_group("infrastructure", "monitoring")
      ref = test_instance.aws_iam_group(:infra_readonly, pattern)
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("infrastructure-readonly-monitoring")
      expect(attrs[:path]).to eq("/readonly/")
      expect(ref.readonly_group?).to eq(true)
      expect(ref.security_risk_level).to eq(:low)
    end
    
    it "creates service groups" do
      pattern = Pangea::Resources::AWS::GroupPatterns.service_group("user-api", "operator")
      ref = test_instance.aws_iam_group(:api_operators, pattern)
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("user-api-operator")
      expect(attrs[:path]).to eq("/services/user-api/")
    end
    
    it "creates cross-functional groups" do
      pattern = Pangea::Resources::AWS::GroupPatterns.cross_functional_group("data-platform", ["engineering", "analytics"])
      ref = test_instance.aws_iam_group(:data_platform_team, pattern)
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("data-platform-cross-functional")
      expect(attrs[:path]).to eq("/cross-functional/engineering-analytics/")
    end
    
    it "creates compliance groups" do
      pattern = Pangea::Resources::AWS::GroupPatterns.compliance_group("soc2", "auditor")
      ref = test_instance.aws_iam_group(:soc2_auditors, pattern)
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("soc2-auditor")
      expect(attrs[:path]).to eq("/compliance/soc2/")
    end
    
    it "creates CI/CD groups" do
      pattern = Pangea::Resources::AWS::GroupPatterns.cicd_group("deployment", "production")
      ref = test_instance.aws_iam_group(:cicd_prod, pattern)
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("cicd-deployment-production")
      expect(attrs[:path]).to eq("/cicd/")
    end
    
    it "creates emergency access groups" do
      pattern = Pangea::Resources::AWS::GroupPatterns.emergency_group("breakglass")
      ref = test_instance.aws_iam_group(:emergency, pattern)
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("emergency-breakglass")
      expect(attrs[:path]).to eq("/emergency/")
    end
  end
  
  describe "resource reference integration" do
    it "provides terraform interpolation syntax for outputs" do
      ref = test_instance.aws_iam_group(:test_group, {
        name: "test-developers"
      })
      
      expect(ref.outputs[:id]).to eq("${aws_iam_group.test_group.id}")
      expect(ref.outputs[:arn]).to eq("${aws_iam_group.test_group.arn}")
      expect(ref.outputs[:name]).to eq("${aws_iam_group.test_group.name}")
      expect(ref.outputs[:unique_id]).to eq("${aws_iam_group.test_group.unique_id}")
    end
    
    it "can be used with other AWS resources" do
      group_ref = test_instance.aws_iam_group(:app_devs, {
        name: "application-developers",
        path: "/teams/"
      })
      
      # Simulate using group reference for policy attachment
      group_name = group_ref.outputs[:name]
      group_arn = group_ref.outputs[:arn]
      
      expect(group_name).to eq("${aws_iam_group.app_devs.name}")
      expect(group_arn).to eq("${aws_iam_group.app_devs.arn}")
    end
  end
  
  describe "error conditions and edge cases" do
    it "handles string keys in attributes" do
      ref = test_instance.aws_iam_group(:string_keys, {
        "name" => "string-key-group",
        "path" => "/test/"
      })
      
      expect(ref.resource_attributes[:name]).to eq("string-key-group")
      expect(ref.resource_attributes[:path]).to eq("/test/")
    end
    
    it "validates special characters in name" do
      valid_names = ["test_group", "test-group", "test.group", "test@group", "test+group", "test,group", "test=group"]
      
      valid_names.each do |name|
        attrs = Pangea::Resources::AWS::IamGroupAttributes.new({ name: name })
        expect(attrs.name).to eq(name)
      end
    end
    
    it "categorizes complex group names correctly" do
      complex_cases = {
        "engineering-developers-production" => :developer,
        "platform-infrastructure-admins" => :administrative,
        "finance-readonly-audit" => :readonly,
        "production-deployment-ops" => :operations
      }
      
      complex_cases.each do |name, expected_category|
        attrs = Pangea::Resources::AWS::IamGroupAttributes.new({ name: name })
        expect(attrs.group_category).to eq(expected_category)
      end
    end
  end
  
  describe "security validation" do
    # Suppress security warnings during tests
    before do
      allow($stdout).to receive(:puts)
    end
    
    it "warns about overly broad group names" do
      expect($stdout).to receive(:puts).with(/very broad/)
      
      Pangea::Resources::AWS::IamGroupAttributes.new({
        name: "all-users"
      })
    end
    
    it "warns about admin groups without path structure" do
      expect($stdout).to receive(:puts).with(/should be in organized path/)
      
      Pangea::Resources::AWS::IamGroupAttributes.new({
        name: "platform-admins",
        path: "/"
      })
    end
    
    it "warns about environment groups without proper paths" do
      expect($stdout).to receive(:puts).with(/should be in environment-specific path/)
      
      Pangea::Resources::AWS::IamGroupAttributes.new({
        name: "production-deploy",
        path: "/generic/"
      })
    end
  end
end