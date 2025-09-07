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

RSpec.describe "aws_vpc" do
  include Pangea::Resources::AWS
  
  describe "basic functionality" do
    it "creates a resource reference" do
      ref = aws_vpc(:test, { cidr_block: "10.0.0.0/16" })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_vpc')
      expect(ref.name).to eq(:test)
    end
    
    it "validates required attributes" do
      expect {
        aws_vpc(:test, {})
      }.to raise_error(Dry::Struct::Error, /missing/)
    end
    
    it "rejects invalid CIDR blocks" do
      expect {
        aws_vpc(:test, { cidr_block: "invalid-cidr" })
      }.to raise_error(Dry::Types::ConstraintError)
    end

    it "rejects CIDR blocks that are too large" do
      expect {
        aws_vpc(:test, { cidr_block: "10.0.0.0/8" })
      }.to raise_error(Dry::Struct::Error, /too large/)
    end

    it "rejects CIDR blocks that are too small" do
      expect {
        aws_vpc(:test, { cidr_block: "10.0.0.0/29" })
      }.to raise_error(Dry::Struct::Error, /too small/)
    end
  end

  describe "attributes and defaults" do
    it "uses provided attributes" do
      ref = aws_vpc(:test, {
        cidr_block: "10.0.0.0/16",
        enable_dns_hostnames: false,
        enable_dns_support: false,
        instance_tenancy: "dedicated",
        tags: { Name: "test-vpc" }
      })
      
      expect(ref.resource_attributes[:cidr_block]).to eq("10.0.0.0/16")
      expect(ref.resource_attributes[:enable_dns_hostnames]).to eq(false)
      expect(ref.resource_attributes[:enable_dns_support]).to eq(false)
      expect(ref.resource_attributes[:instance_tenancy]).to eq("dedicated")
      expect(ref.resource_attributes[:tags]).to eq({ Name: "test-vpc" })
    end

    it "applies default values" do
      ref = aws_vpc(:test, { cidr_block: "10.0.0.0/16" })
      
      expect(ref.resource_attributes[:enable_dns_hostnames]).to eq(true)
      expect(ref.resource_attributes[:enable_dns_support]).to eq(true)
    end
  end

  describe "outputs" do
    it "provides standard VPC outputs" do
      ref = aws_vpc(:test, { cidr_block: "10.0.0.0/16" })
      
      expect(ref.outputs[:id]).to eq("${aws_vpc.test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_vpc.test.arn}")
      expect(ref.outputs[:cidr_block]).to eq("${aws_vpc.test.cidr_block}")
      expect(ref.outputs[:default_security_group_id]).to eq("${aws_vpc.test.default_security_group_id}")
      expect(ref.outputs[:default_route_table_id]).to eq("${aws_vpc.test.default_route_table_id}")
      expect(ref.outputs[:default_network_acl_id]).to eq("${aws_vpc.test.default_network_acl_id}")
    end
  end
end