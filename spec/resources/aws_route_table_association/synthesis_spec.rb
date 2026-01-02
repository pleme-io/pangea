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
require 'terraform-synthesizer'
require 'pangea/resources/aws_route_table_association/resource'

RSpec.describe "aws_route_table_association synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with subnet association" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route_table_association(:subnet_assoc, {
          route_table_id: "rtb-12345678",
          subnet_id: "subnet-12345678"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_route_table_association")
      expect(result["resource"]["aws_route_table_association"]).to have_key("subnet_assoc")

      assoc_config = result["resource"]["aws_route_table_association"]["subnet_assoc"]
      expect(assoc_config["route_table_id"]).to eq("rtb-12345678")
      expect(assoc_config["subnet_id"]).to eq("subnet-12345678")
    end

    it "generates valid terraform JSON with gateway association" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route_table_association(:gateway_assoc, {
          route_table_id: "rtb-12345678",
          gateway_id: "igw-12345678"
        })
      end

      result = synthesizer.synthesis
      assoc_config = result["resource"]["aws_route_table_association"]["gateway_assoc"]

      expect(assoc_config["route_table_id"]).to eq("rtb-12345678")
      expect(assoc_config["gateway_id"]).to eq("igw-12345678")
    end
  end

  describe "resource references" do
    it "returns a ResourceReference with correct outputs for subnet association" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_route_table_association(:test, {
          route_table_id: "rtb-12345678",
          subnet_id: "subnet-12345678"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.id).to eq("${aws_route_table_association.test.id}")
      expect(ref.route_table_id).to eq("${aws_route_table_association.test.route_table_id}")
      expect(ref.subnet_id).to eq("${aws_route_table_association.test.subnet_id}")
    end

    it "returns a ResourceReference with correct outputs for gateway association" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_route_table_association(:gateway_test, {
          route_table_id: "rtb-12345678",
          gateway_id: "igw-12345678"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.id).to eq("${aws_route_table_association.gateway_test.id}")
      expect(ref.route_table_id).to eq("${aws_route_table_association.gateway_test.route_table_id}")
      expect(ref.gateway_id).to eq("${aws_route_table_association.gateway_test.gateway_id}")
    end

    it "includes computed properties for association type" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_route_table_association(:subnet_test, {
          route_table_id: "rtb-12345678",
          subnet_id: "subnet-12345678"
        })
      end

      expect(ref.computed_properties[:is_subnet_association]).to eq(true)
      expect(ref.computed_properties[:is_gateway_association]).to eq(false)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route_table_association(:test, {
          route_table_id: "rtb-12345678",
          subnet_id: "subnet-12345678"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_route_table_association"]).to be_a(Hash)
      expect(result["resource"]["aws_route_table_association"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      assoc_config = result["resource"]["aws_route_table_association"]["test"]
      expect(assoc_config).to have_key("route_table_id")
      expect(assoc_config).to have_key("subnet_id")
    end
  end
end
