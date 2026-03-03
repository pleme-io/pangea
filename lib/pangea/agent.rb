# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'json'
require 'pangea/version'
require 'pangea/configuration'
require 'pangea/compilation/template_compiler'
require_relative 'agent/listing'
require_relative 'agent/analysis'
require_relative 'agent/compilation'
require_relative 'agent/helpers'

module Pangea
  # Agent-friendly API for Pangea operations
  # Provides JSON-based responses for all operations
  class Agent
    include Listing
    include Analysis
    include Compilation
    include Helpers

    attr_reader :options

    def initialize(options = {})
      @options = options
      @compiler = ::Pangea::Compilation::TemplateCompiler.new
    end
  end
end
