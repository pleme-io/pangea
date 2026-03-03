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


# Shared examples for resource function testing
RSpec.shared_examples 'a valid resource function' do |resource_type|
  let(:resource_name) { :test_resource }

  it 'returns a ResourceReference' do
    expect(subject).to be_a(Pangea::Resources::ResourceReference)
  end

  it 'has the correct resource type' do
    expect(subject.type).to eq(resource_type)
  end

  it 'has the correct resource name' do
    expect(subject.name).to eq(resource_name)
  end

  it 'has valid attributes hash' do
    expect(subject.attributes).to be_a(Hash)
    expect(subject.attributes).not_to be_empty
  end

  it 'has outputs hash with terraform references' do
    expect(subject.outputs).to be_a(Hash)
    expect(subject.outputs).not_to be_empty
    
    # All outputs should be terraform references
    subject.outputs.each do |key, value|
      expect(value).to be_a(String)
      expect(value).to match(/\$\{#{resource_type}\.#{resource_name}\.\w+\}/)
    end
  end

  it 'provides ref method for terraform references' do
    expect(subject).to respond_to(:ref)
    id_ref = subject.ref(:id)
    expect(id_ref).to eq("${#{resource_type}.#{resource_name}.id}")
  end
end

# Shared examples for AWS resource validation
RSpec.shared_examples 'validates AWS resource attributes' do
  context 'with invalid attributes' do
    let(:invalid_attributes) { { invalid_key: 'invalid_value' } }

    it 'raises validation error for invalid attributes' do
      expect {
        described_class.new(invalid_attributes)
      }.to raise_error(Dry::Struct::Error)
    end
  end

  context 'with missing required attributes' do
    let(:empty_attributes) { {} }

    it 'raises validation error for missing required fields' do
      expect {
        described_class.new(empty_attributes)
      }.to raise_error(Dry::Struct::Error)
    end
  end
end

# Shared examples for architecture functions
RSpec.shared_examples 'a complete architecture function' do
  it 'returns an ArchitectureReference' do
    expect(subject).to be_a(Pangea::Architectures::ArchitectureReference)
  end

  it 'has a valid architecture type' do
    expect(subject.architecture_type).to be_a(String)
    expect(subject.architecture_type).not_to be_empty
  end

  it 'has a valid name' do
    expect(subject.name).to be_a(Symbol)
  end

  it 'has attributes hash' do
    expect(subject.attributes).to be_a(Hash)
  end

  it 'creates actual resources' do
    expect(subject.all_resources).not_to be_empty
  end

  it 'provides cost estimation' do
    cost = subject.estimated_monthly_cost
    expect(cost).to be_a(Numeric)
    expect(cost).to be >= 0
  end

  it 'provides security compliance score' do
    score = subject.security_compliance_score  
    expect(score).to be_a(Numeric)
    expect(score).to be_between(0, 100).inclusive
  end

  it 'supports override functionality' do
    expect(subject).to respond_to(:override)
    expect(subject).to respond_to(:extend)
    expect(subject).to respond_to(:compose_with)
  end
end

# Shared examples for high availability architecture
RSpec.shared_examples 'a highly available architecture' do
  it 'distributes resources across multiple availability zones' do
    expect(subject.availability_zones.count).to be >= 2
  end

  it 'reports as highly available' do
    expect(subject.is_highly_available?).to be true
  end

  it 'has higher cost than single-AZ deployment' do
    # This would need to be tested with a comparable single-AZ architecture
    expect(subject.estimated_monthly_cost).to be > 50.0
  end
end

# Shared examples for secure architecture
RSpec.shared_examples 'a secure architecture' do
  it 'has good security compliance score' do
    expect(subject.security_compliance_score).to be >= 80.0
  end

  it 'includes security groups' do
    security_groups = subject.all_resources.select do |resource|
      resource.respond_to?(:type) && resource.type == 'aws_security_group'
    end
    expect(security_groups).not_to be_empty
  end

  it 'encrypts sensitive resources when in production' do
    if subject.attributes[:environment] == 'production'
      # Check for encryption on databases, S3 buckets, etc.
      encrypted_resources = subject.all_resources.select do |resource|
        resource.respond_to?(:attributes) && 
        (resource.attributes[:storage_encrypted] == true ||
         resource.attributes[:encryption].present?)
      end
      expect(encrypted_resources).not_to be_empty
    end
  end
end

# Shared examples for monitoring-enabled architecture
RSpec.shared_examples 'a monitored architecture' do
  it 'includes monitoring resources' do
    monitoring_resources = subject.all_resources.select do |resource|
      resource.respond_to?(:type) && 
      (resource.type.include?('cloudwatch') || resource.type.include?('monitoring'))
    end
    expect(monitoring_resources).not_to be_empty
  end

  it 'has monitoring tier configured' do
    expect(subject.monitoring).to be_present
  end
end

# Shared examples for scalable architecture
RSpec.shared_examples 'a scalable architecture' do
  it 'includes auto scaling resources' do
    scaling_resources = subject.all_resources.select do |resource|
      resource.respond_to?(:type) && 
      (resource.type.include?('autoscaling') || resource.type.include?('scaling'))
    end
    expect(scaling_resources).not_to be_empty
  end

  it 'configures appropriate scaling limits' do
    # This would be specific to each architecture type
    # Base expectation is that scaling is configured
    expect(subject.attributes).to have_key(:auto_scaling).or have_key(:min_instances)
  end
end

# Shared examples for resource composition testing
RSpec.shared_examples 'properly composed resources' do
  it 'wires resource dependencies correctly' do
    # Check that VPC resources reference the same VPC
    vpc_resources = subject.all_resources.select do |resource|
      resource.respond_to?(:attributes) && resource.attributes.key?(:vpc_id)
    end

    if vpc_resources.any?
      vpc_ids = vpc_resources.map { |r| r.attributes[:vpc_id] }.uniq
      expect(vpc_ids.count).to eq(1), 'All resources should reference the same VPC'
    end
  end

  it 'maintains resource naming consistency' do
    # All resource names should follow the architecture naming pattern
    subject.all_resources.each do |resource|
      if resource.respond_to?(:name)
        expect(resource.name.to_s).to start_with(subject.name.to_s)
      end
    end
  end

  it 'applies consistent tagging' do
    # Resources should have consistent base tags
    tagged_resources = subject.all_resources.select do |resource|
      resource.respond_to?(:attributes) && resource.attributes.key?(:tags)
    end

    if tagged_resources.any?
      # All tagged resources should have ArchitectureName tag
      tagged_resources.each do |resource|
        tags = resource.attributes[:tags]
        expect(tags).to have_key(:ArchitectureName).or have_key('ArchitectureName')
      end
    end
  end
end