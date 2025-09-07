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

# Load aws_iam_user resource and types for testing
require 'pangea/resources/aws_iam_user/resource'
require 'pangea/resources/aws_iam_user/types'

RSpec.describe "aws_iam_user resource function" do
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
  
  describe "IamUserAttributes validation" do
    it "accepts minimal configuration with required name" do
      attrs = Pangea::Resources::AWS::IamUserAttributes.new({
        name: "test-user"
      })
      
      expect(attrs.name).to eq("test-user")
      expect(attrs.path).to eq("/")
      expect(attrs.force_destroy).to eq(false)
    end
    
    it "accepts custom path and permissions boundary" do
      attrs = Pangea::Resources::AWS::IamUserAttributes.new({
        name: "test-user",
        path: "/developers/",
        permissions_boundary: "arn:aws:iam::123456789012:policy/DeveloperBoundary",
        force_destroy: true
      })
      
      expect(attrs.path).to eq("/developers/")
      expect(attrs.permissions_boundary).to eq("arn:aws:iam::123456789012:policy/DeveloperBoundary")
      expect(attrs.force_destroy).to eq(true)
    end
    
    it "validates user name format" do
      expect {
        Pangea::Resources::AWS::IamUserAttributes.new({
          name: "invalid user name with spaces"
        })
      }.to raise_error(Dry::Struct::Error, /must contain only alphanumeric characters/)
    end
    
    it "validates user name length" do
      expect {
        Pangea::Resources::AWS::IamUserAttributes.new({
          name: "a" * 65
        })
      }.to raise_error(Dry::Struct::Error, /cannot exceed 64 characters/)
    end
    
    it "validates path format" do
      expect {
        Pangea::Resources::AWS::IamUserAttributes.new({
          name: "test-user",
          path: "missing-leading-slash"
        })
      }.to raise_error(Dry::Struct::Error, /must start with '\\/'/)
    end
    
    it "validates path length" do
      expect {
        Pangea::Resources::AWS::IamUserAttributes.new({
          name: "test-user",
          path: "/" + "a" * 511 + "/"
        })
      }.to raise_error(Dry::Struct::Error, /cannot exceed 512 characters/)
    end
    
    it "validates permissions boundary ARN format when provided" do
      expect {
        Pangea::Resources::AWS::IamUserAttributes.new({
          name: "test-user",
          permissions_boundary: "invalid-arn"
        })
      }.to raise_error(Dry::Struct::Error, /must be a valid IAM policy ARN/)
    end
    
    it "detects administrative users" do
      admin_names = ["admin-user", "super-user", "root-user"]
      
      admin_names.each do |name|
        attrs = Pangea::Resources::AWS::IamUserAttributes.new({ name: name })
        expect(attrs.administrative_user?).to eq(true)
        expect(attrs.user_category).to eq(:administrative)
      end
    end
    
    it "detects service users" do
      service_names = ["api-service", "app-svc", "system-user"]
      
      service_names.each do |name|
        attrs = Pangea::Resources::AWS::IamUserAttributes.new({ name: name })
        expect(attrs.service_user?).to eq(true)
        expect(attrs.user_category).to eq(:service_account)
      end
    end
    
    it "detects human users" do
      human_names = ["john.doe", "jane.smith", "alice.wilson"]
      
      human_names.each do |name|
        attrs = Pangea::Resources::AWS::IamUserAttributes.new({ name: name })
        expect(attrs.human_user?).to eq(true)
        expect(attrs.user_category).to eq(:human_user)
      end
    end
    
    it "handles organizational paths" do
      attrs = Pangea::Resources::AWS::IamUserAttributes.new({
        name: "test-user",
        path: "/developers/frontend/"
      })
      
      expect(attrs.organizational_path?).to eq(true)
      expect(attrs.organizational_unit).to eq("developers")
    end
    
    it "generates user ARN" do
      attrs = Pangea::Resources::AWS::IamUserAttributes.new({
        name: "test-user",
        path: "/developers/"
      })
      
      expect(attrs.user_arn).to eq("arn:aws:iam::123456789012:user/developers/test-user")
      expect(attrs.user_arn("999888777666")).to eq("arn:aws:iam::999888777666:user/developers/test-user")
    end
    
    it "extracts permissions boundary policy name" do
      attrs = Pangea::Resources::AWS::IamUserAttributes.new({
        name: "test-user",
        permissions_boundary: "arn:aws:iam::123456789012:policy/DeveloperBoundary"
      })
      
      expect(attrs.has_permissions_boundary?).to eq(true)
      expect(attrs.permissions_boundary_policy_name).to eq("DeveloperBoundary")
    end
    
    it "assesses security risk levels" do
      # High risk - admin without boundary
      attrs1 = Pangea::Resources::AWS::IamUserAttributes.new({
        name: "admin-user"
      })
      expect(attrs1.security_risk_level).to eq(:high)
      
      # Low risk - user with boundary
      attrs2 = Pangea::Resources::AWS::IamUserAttributes.new({
        name: "dev-user",
        permissions_boundary: "arn:aws:iam::123456789012:policy/DevBoundary"
      })
      expect(attrs2.security_risk_level).to eq(:low)
      
      # Medium risk - service without boundary
      attrs3 = Pangea::Resources::AWS::IamUserAttributes.new({
        name: "api-service"
      })
      expect(attrs3.security_risk_level).to eq(:medium)
    end
    
    it "generates secure random passwords" do
      password = Pangea::Resources::AWS::IamUserAttributes.generate_secure_password
      
      expect(password.length).to eq(16)
      expect(password).to match(/[A-Z]/)  # Has uppercase
      expect(password).to match(/[a-z]/)  # Has lowercase
      expect(password).to match(/[0-9]/)  # Has numbers
      expect(password).to match(/[!@#$%^&*]/)  # Has symbols
      
      # Test custom length
      long_password = Pangea::Resources::AWS::IamUserAttributes.generate_secure_password(32)
      expect(long_password.length).to eq(32)
    end
  end
  
  describe "aws_iam_user function behavior" do
    it "creates a user with minimal attributes" do
      ref = test_instance.aws_iam_user(:test_user, {
        name: "test-user"
      })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_iam_user')
      expect(ref.name).to eq(:test_user)
    end
    
    it "creates a user with custom path and permissions boundary" do
      ref = test_instance.aws_iam_user(:dev_user, {
        name: "alice.smith",
        path: "/developers/",
        permissions_boundary: "arn:aws:iam::123456789012:policy/DeveloperBoundary",
        force_destroy: true
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("alice.smith")
      expect(attrs[:path]).to eq("/developers/")
      expect(attrs[:permissions_boundary]).to eq("arn:aws:iam::123456789012:policy/DeveloperBoundary")
      expect(attrs[:force_destroy]).to eq(true)
    end
    
    it "creates a user with tags" do
      ref = test_instance.aws_iam_user(:tagged_user, {
        name: "tagged-user",
        tags: {
          Department: "Engineering",
          Team: "Platform",
          Environment: "Production"
        }
      })
      
      expect(ref.resource_attributes[:tags]).to eq({
        Department: "Engineering",
        Team: "Platform",
        Environment: "Production"
      })
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_iam_user(:test_user, {
        name: "test-user"
      })
      
      expected_outputs = [:id, :arn, :name, :path, :permissions_boundary, :unique_id, :tags_all]
      
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_iam_user.test_user.")
      end
    end
    
    it "provides computed properties" do
      ref = test_instance.aws_iam_user(:admin_user, {
        name: "platform-admin",
        path: "/admins/",
        permissions_boundary: "arn:aws:iam::123456789012:policy/AdminBoundary"
      })
      
      expect(ref.administrative_user?).to eq(true)
      expect(ref.service_user?).to eq(false)
      expect(ref.human_user?).to eq(false)
      expect(ref.organizational_path?).to eq(true)
      expect(ref.organizational_unit).to eq("admins")
      expect(ref.user_category).to eq(:administrative)
      expect(ref.security_risk_level).to eq(:low)  # Has boundary
      expect(ref.has_permissions_boundary?).to eq(true)
      expect(ref.permissions_boundary_policy_name).to eq("AdminBoundary")
    end
  end
  
  describe "UserPatterns module usage" do
    it "creates developer user pattern" do
      pattern = Pangea::Resources::AWS::UserPatterns.developer_user("alice.smith", "frontend")
      ref = test_instance.aws_iam_user(:dev_alice, pattern)
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("alice.smith")
      expect(attrs[:path]).to eq("/frontend/")
      expect(attrs[:permissions_boundary]).to include("DeveloperPermissionsBoundary")
      expect(attrs[:tags][:UserType]).to eq("Developer")
      expect(attrs[:tags][:Department]).to eq("Frontend")
    end
    
    it "creates service account pattern" do
      pattern = Pangea::Resources::AWS::UserPatterns.service_account_user("user-api", "production")
      ref = test_instance.aws_iam_user(:api_service, pattern)
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("user-api-service")
      expect(attrs[:path]).to eq("/service-accounts/production/")
      expect(attrs[:force_destroy]).to eq(true)
      expect(attrs[:tags][:UserType]).to eq("ServiceAccount")
      expect(attrs[:tags][:Environment]).to eq("production")
    end
    
    it "creates CI/CD user pattern" do
      pattern = Pangea::Resources::AWS::UserPatterns.cicd_user("web-app-deploy", "github.com/company/web-app")
      ref = test_instance.aws_iam_user(:cicd_user, pattern)
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("web-app-deploy-cicd")
      expect(attrs[:path]).to eq("/cicd/")
      expect(attrs[:force_destroy]).to eq(true)
      expect(attrs[:tags][:UserType]).to eq("CICD")
      expect(attrs[:tags][:Repository]).to eq("github.com/company/web-app")
    end
    
    it "creates admin user pattern" do
      pattern = Pangea::Resources::AWS::UserPatterns.admin_user("bob.wilson", "infrastructure")
      ref = test_instance.aws_iam_user(:admin_bob, pattern)
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("bob.wilson.admin")
      expect(attrs[:path]).to eq("/admins/infrastructure/")
      expect(attrs[:permissions_boundary]).to include("AdminPermissionsBoundary")
      expect(attrs[:tags][:RequiresApproval]).to eq("true")
    end
    
    it "creates readonly user pattern" do
      pattern = Pangea::Resources::AWS::UserPatterns.readonly_user("audit", "compliance")
      ref = test_instance.aws_iam_user(:audit_user, pattern)
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("audit.readonly")
      expect(attrs[:path]).to eq("/readonly/")
      expect(attrs[:permissions_boundary]).to include("ReadOnlyPermissionsBoundary")
      expect(attrs[:tags][:Purpose]).to eq("Compliance")
    end
    
    it "creates emergency user pattern" do
      pattern = Pangea::Resources::AWS::UserPatterns.emergency_user("breakglass")
      ref = test_instance.aws_iam_user(:emergency, pattern)
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("breakglass.emergency")
      expect(attrs[:path]).to eq("/emergency/")
      expect(attrs[:permissions_boundary]).to be_nil  # No boundary for emergency
      expect(attrs[:tags][:UserType]).to eq("Emergency")
      expect(attrs[:tags][:AuditRequired]).to eq("true")
    end
    
    it "creates cross-account user pattern" do
      pattern = Pangea::Resources::AWS::UserPatterns.cross_account_user("shared-access", "987654321098")
      ref = test_instance.aws_iam_user(:cross_account, pattern)
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("shared-access.crossaccount")
      expect(attrs[:path]).to eq("/cross-account/")
      expect(attrs[:tags][:TargetAccount]).to eq("987654321098")
      expect(attrs[:tags][:AccessPattern]).to eq("AssumeRole")
    end
  end
  
  describe "PermissionsBoundaries module usage" do
    it "provides boundary constants" do
      expect(Pangea::Resources::AWS::PermissionsBoundaries::DEVELOPER_BOUNDARY).to include("DeveloperPermissionsBoundary")
      expect(Pangea::Resources::AWS::PermissionsBoundaries::SERVICE_ACCOUNT_BOUNDARY).to include("ServiceAccountPermissionsBoundary")
      expect(Pangea::Resources::AWS::PermissionsBoundaries::ADMIN_BOUNDARY).to include("AdminPermissionsBoundary")
    end
    
    it "provides boundary lookup by user type" do
      expect(Pangea::Resources::AWS::PermissionsBoundaries.boundary_for_user_type(:developer))
        .to eq(Pangea::Resources::AWS::PermissionsBoundaries::DEVELOPER_BOUNDARY)
      
      expect(Pangea::Resources::AWS::PermissionsBoundaries.boundary_for_user_type(:administrator))
        .to eq(Pangea::Resources::AWS::PermissionsBoundaries::ADMIN_BOUNDARY)
      
      expect(Pangea::Resources::AWS::PermissionsBoundaries.boundary_for_user_type(:unknown))
        .to be_nil
    end
    
    it "lists all boundaries" do
      all_boundaries = Pangea::Resources::AWS::PermissionsBoundaries.all_boundaries
      
      expect(all_boundaries).to include(Pangea::Resources::AWS::PermissionsBoundaries::DEVELOPER_BOUNDARY)
      expect(all_boundaries).to include(Pangea::Resources::AWS::PermissionsBoundaries::CICD_BOUNDARY)
      expect(all_boundaries.all? { |b| b.match?(/\Aarn:aws:iam::[0-9]{12}:policy\//) }).to eq(true)
    end
  end
  
  describe "resource reference integration" do
    it "provides terraform interpolation syntax for outputs" do
      ref = test_instance.aws_iam_user(:test_user, {
        name: "test-user"
      })
      
      expect(ref.outputs[:id]).to eq("${aws_iam_user.test_user.id}")
      expect(ref.outputs[:arn]).to eq("${aws_iam_user.test_user.arn}")
      expect(ref.outputs[:name]).to eq("${aws_iam_user.test_user.name}")
      expect(ref.outputs[:unique_id]).to eq("${aws_iam_user.test_user.unique_id}")
    end
    
    it "can be used with other AWS resources" do
      user_ref = test_instance.aws_iam_user(:app_user, {
        name: "application-user",
        path: "/applications/"
      })
      
      # Simulate using user reference for policy attachment
      user_name = user_ref.outputs[:name]
      user_arn = user_ref.outputs[:arn]
      
      expect(user_name).to eq("${aws_iam_user.app_user.name}")
      expect(user_arn).to eq("${aws_iam_user.app_user.arn}")
    end
  end
  
  describe "error conditions and edge cases" do
    it "handles string keys in attributes" do
      ref = test_instance.aws_iam_user(:string_keys, {
        "name" => "string-key-user",
        "path" => "/test/",
        "force_destroy" => true
      })
      
      expect(ref.resource_attributes[:name]).to eq("string-key-user")
      expect(ref.resource_attributes[:path]).to eq("/test/")
      expect(ref.resource_attributes[:force_destroy]).to eq(true)
    end
    
    it "validates special characters in user names" do
      valid_names = ["test_user", "test-user", "test.user", "test@user", "test+user", "test,user", "test=user"]
      
      valid_names.each do |name|
        attrs = Pangea::Resources::AWS::IamUserAttributes.new({ name: name })
        expect(attrs.name).to eq(name)
      end
    end
    
    it "categorizes complex user names correctly" do
      complex_cases = {
        "admin.service" => :administrative,  # Admin takes precedence
        "john.doe.svc" => :service_account,  # Service takes precedence over human pattern
        "developer" => :generic,             # No clear category
        "alice.smith" => :human_user         # Human pattern
      }
      
      complex_cases.each do |name, expected_category|
        attrs = Pangea::Resources::AWS::IamUserAttributes.new({ name: name })
        expect(attrs.user_category).to eq(expected_category)
      end
    end
  end
  
  describe "security validation" do
    # Suppress security warnings during tests
    before do
      allow($stdout).to receive(:puts)
    end
    
    it "warns about admin users without permissions boundary" do
      expect($stdout).to receive(:puts).with(/should have a permissions boundary/)
      
      Pangea::Resources::AWS::IamUserAttributes.new({
        name: "platform-admin"
      })
    end
    
    it "warns about unsafe user names" do
      expect($stdout).to receive(:puts).with(/matches common attack targets/)
      
      Pangea::Resources::AWS::IamUserAttributes.new({
        name: "root"
      })
    end
    
    it "warns about users in root path" do
      expect($stdout).to receive(:puts).with(/consider organizational path structure/)
      
      Pangea::Resources::AWS::IamUserAttributes.new({
        name: "generic-user"
      })
    end
    
    it "does not warn for properly configured users" do
      expect($stdout).not_to receive(:puts)
      
      Pangea::Resources::AWS::IamUserAttributes.new({
        name: "alice.smith",
        path: "/developers/",
        permissions_boundary: "arn:aws:iam::123456789012:policy/DeveloperBoundary"
      })
    end
  end
end