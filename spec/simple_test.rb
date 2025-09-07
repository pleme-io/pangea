# frozen_string_literal: true

# Simple test to validate our testing framework without complex dependencies
require 'minitest/autorun'

class SimplePangeaTest < Minitest::Test
  def setup
    # Add lib to load path
    lib_path = File.expand_path('../lib', __dir__)
    $LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)
  end

  def test_pangea_loads
    require 'pangea'
    assert_kind_of Module, Pangea
    assert_respond_to Pangea, :configuration
  end

  def test_pangea_types_loads
    require 'pangea/types'
    assert_kind_of Module, Pangea::Types
  end

  def test_dry_types_available
    require 'dry-types'
    types = Dry::Types.module_eval { self }
    assert_kind_of Module, types
  end

  def test_dry_struct_available
    require 'dry-struct'
    struct = Dry::Struct
    assert_kind_of Class, struct
  end

  def test_terraform_synthesizer_available
    require 'terraform-synthesizer'
    synthesizer = TerraformSynthesizer
    assert_kind_of Class, synthesizer
  end

  def test_abstract_synthesizer_available
    require 'abstract-synthesizer'
    synthesizer = AbstractSynthesizer
    assert_kind_of Class, synthesizer
  end
end