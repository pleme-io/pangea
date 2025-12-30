# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'aws_snow_family/snowball'
require_relative 'aws_snow_family/snowcone'
require_relative 'aws_snow_family/snowmobile'
require_relative 'aws_snow_family/datasync'

module Pangea
  module Resources
    module AWS
      # AWS Snow Family - Edge computing and data transfer devices
      # Snow Family provides physical devices for edge computing, data collection, and migration
      # in environments with limited or no connectivity
      include SnowFamily
    end
  end
end
