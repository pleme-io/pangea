# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

# AWS Outposts - Bring AWS infrastructure and services on premises
require_relative 'aws_outposts/outpost'
require_relative 'aws_outposts/site'
require_relative 'aws_outposts/resources'

module Pangea
  module Resources
    module AWS
      include OutpostsOutpost
      include OutpostsSite
      include OutpostsResources
    end
  end
end
