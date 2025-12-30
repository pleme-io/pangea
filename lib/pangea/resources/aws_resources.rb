# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

# Load all AWS resource implementations organized by category
require 'pangea/resources/base'
require_relative 'aws_resources/core'
require_relative 'aws_resources/storage'
require_relative 'aws_resources/database'
require_relative 'aws_resources/compute'
require_relative 'aws_resources/integration'
require_relative 'aws_resources/analytics'
require_relative 'aws_resources/security'
require_relative 'aws_resources/management'
require_relative 'aws_resources/devops'
require_relative 'aws_resources/ml'
require_relative 'aws_resources/specialty'
require_relative 'aws_resources/governance'

module Pangea
  module Resources
    # AWS resource functions module that includes all AWS resource implementations
    # Each resource is implemented in its own directory under aws_*/
    module AWS
      include Base
    end
  end
end
