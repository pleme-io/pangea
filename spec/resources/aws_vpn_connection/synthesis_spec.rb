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
require 'pangea/resources/aws_vpn_connection/resource'

RSpec.describe "aws_vpn_connection synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with VPN gateway" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpn_connection(:test, {
          customer_gateway_id: "cgw-12345678",
          type: "ipsec.1",
          vpn_gateway_id: "vgw-87654321",
          tags: { Name: "test-vpn-connection" }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_vpn_connection")
      expect(result["resource"]["aws_vpn_connection"]).to have_key("test")

      vpn_config = result["resource"]["aws_vpn_connection"]["test"]
      expect(vpn_config["customer_gateway_id"]).to eq("cgw-12345678")
      expect(vpn_config["type"]).to eq("ipsec.1")
      expect(vpn_config["vpn_gateway_id"]).to eq("vgw-87654321")
    end

    it "generates VPN connection with Transit Gateway" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpn_connection(:transit_gw, {
          customer_gateway_id: "cgw-12345678",
          type: "ipsec.1",
          transit_gateway_id: "tgw-12345678",
          tags: { Name: "transit-gw-vpn-connection" }
        })
      end

      result = synthesizer.synthesis
      vpn_config = result["resource"]["aws_vpn_connection"]["transit_gw"]

      expect(vpn_config["transit_gateway_id"]).to eq("tgw-12345678")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpn_connection(:tagged, {
          customer_gateway_id: "cgw-12345678",
          type: "ipsec.1",
          vpn_gateway_id: "vgw-87654321",
          tags: { Name: "tagged-vpn", Environment: "production" }
        })
      end

      result = synthesizer.synthesis
      vpn_config = result["resource"]["aws_vpn_connection"]["tagged"]

      expect(vpn_config).to have_key("tags")
      expect(vpn_config["tags"]["Name"]).to eq("tagged-vpn")
      expect(vpn_config["tags"]["Environment"]).to eq("production")
    end

    it "supports static routing" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpn_connection(:static, {
          customer_gateway_id: "cgw-12345678",
          type: "ipsec.1",
          vpn_gateway_id: "vgw-87654321",
          static_routes_only: true,
          tags: { Name: "static-vpn-connection" }
        })
      end

      result = synthesizer.synthesis
      vpn_config = result["resource"]["aws_vpn_connection"]["static"]

      expect(vpn_config["static_routes_only"]).to eq(true)
    end

    it "supports tunnel configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpn_connection(:with_tunnels, {
          customer_gateway_id: "cgw-12345678",
          type: "ipsec.1",
          vpn_gateway_id: "vgw-87654321",
          tunnel1_inside_cidr: "169.254.10.0/30",
          tunnel2_inside_cidr: "169.254.11.0/30",
          tunnel1_preshared_key: "supersecretkey1",
          tunnel2_preshared_key: "supersecretkey2",
          tags: { Name: "tunnel-config-vpn" }
        })
      end

      result = synthesizer.synthesis
      vpn_config = result["resource"]["aws_vpn_connection"]["with_tunnels"]

      expect(vpn_config["tunnel1_inside_cidr"]).to eq("169.254.10.0/30")
      expect(vpn_config["tunnel2_inside_cidr"]).to eq("169.254.11.0/30")
      expect(vpn_config["tunnel1_preshared_key"]).to eq("supersecretkey1")
      expect(vpn_config["tunnel2_preshared_key"]).to eq("supersecretkey2")
    end

    it "supports local and remote IPv4 network CIDRs" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpn_connection(:with_cidrs, {
          customer_gateway_id: "cgw-12345678",
          type: "ipsec.1",
          vpn_gateway_id: "vgw-87654321",
          local_ipv4_network_cidr: "10.0.0.0/16",
          remote_ipv4_network_cidr: "192.168.0.0/16",
          tags: { Name: "cidr-vpn-connection" }
        })
      end

      result = synthesizer.synthesis
      vpn_config = result["resource"]["aws_vpn_connection"]["with_cidrs"]

      expect(vpn_config["local_ipv4_network_cidr"]).to eq("10.0.0.0/16")
      expect(vpn_config["remote_ipv4_network_cidr"]).to eq("192.168.0.0/16")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpn_connection(:test, {
          customer_gateway_id: "cgw-12345678",
          type: "ipsec.1",
          vpn_gateway_id: "vgw-87654321"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_vpn_connection"]).to be_a(Hash)
      expect(result["resource"]["aws_vpn_connection"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      vpn_config = result["resource"]["aws_vpn_connection"]["test"]
      expect(vpn_config).to have_key("customer_gateway_id")
      expect(vpn_config).to have_key("type")
    end
  end

  describe "resource reference" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_vpn_connection(:test_ref, {
          customer_gateway_id: "cgw-12345678",
          type: "ipsec.1",
          vpn_gateway_id: "vgw-87654321",
          tags: { Name: "test-vpn-connection" }
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_vpn_connection.test_ref.id}")
      expect(ref.outputs[:arn]).to eq("${aws_vpn_connection.test_ref.arn}")
      expect(ref.outputs[:tunnel1_address]).to eq("${aws_vpn_connection.test_ref.tunnel1_address}")
      expect(ref.outputs[:tunnel2_address]).to eq("${aws_vpn_connection.test_ref.tunnel2_address}")
    end
  end
end
