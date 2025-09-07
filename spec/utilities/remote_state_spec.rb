# spec/utilities/remote_state_spec.rb
require_relative 'test_helper'

RSpec.describe Pangea::Utilities::RemoteState do
  describe "Reference" do
    it "creates a valid reference" do
      ref = described_class.reference('prod', 'network', 'vpc_id')
      
      expect(ref.namespace).to eq('prod')
      expect(ref.template).to eq('network')
      expect(ref.output).to eq('vpc_id')
    end
    
    it "generates correct terraform reference" do
      ref = described_class.reference('prod', 'network', 'vpc_id')
      
      expect(ref.reference_string).to eq('${data.terraform_remote_state.network_state.outputs.vpc_id}')
    end
    
    it "validates required fields" do
      expect {
        described_class.reference('', 'network', 'vpc_id')
      }.to raise_error(ArgumentError, /Namespace cannot be empty/)
    end
  end
  
  describe "DependencyManager" do
    let(:manager) { described_class::DependencyManager.new }
    
    it "tracks dependencies correctly" do
      manager.add_dependency('compute', 'network', ['vpc_id', 'subnet_ids'])
      
      expect(manager.depends_on?('compute', 'network')).to be true
      expect(manager.get_dependencies('compute')).to eq(['network'])
    end
    
    it "calculates correct execution order" do
      manager.add_dependency('app', 'compute')
      manager.add_dependency('compute', 'network')
      
      order = manager.get_execution_order
      
      expect(order).to eq(['network', 'compute', 'app'])
    end
    
    it "detects circular dependencies" do
      manager.add_dependency('a', 'b')
      manager.add_dependency('b', 'c')
      manager.add_dependency('c', 'a')
      
      expect {
        manager.get_execution_order
      }.to raise_error(/Circular dependency detected/)
    end
  end
  
  describe "OutputRegistry" do
    let(:registry) { described_class::OutputRegistry.new }
    
    before { create_test_registry }
    after { FileUtils.rm_rf('.pangea/outputs') }
    
    it "registers outputs" do
      outputs = { vpc_id: 'vpc-123', subnet_ids: ['subnet-1', 'subnet-2'] }
      
      result = registry.register_outputs('network', outputs)
      
      expect(result['outputs']['vpc_id']).to eq('vpc-123')
      expect(result['types']['vpc_id']).to eq('string')
      expect(result['types']['subnet_ids']).to eq('list')
    end
    
    it "retrieves registered outputs" do
      registry.register_outputs('network', { vpc_id: 'vpc-123' })
      
      outputs = registry.available_outputs('network')
      
      expect(outputs['outputs']['vpc_id']).to eq('vpc-123')
    end
    
    it "validates output existence" do
      registry.register_outputs('network', { vpc_id: 'vpc-123' })
      
      expect {
        registry.validate_output_exists!('network', 'invalid_output')
      }.to raise_error(/Output 'invalid_output' not found/)
    end
  end
end