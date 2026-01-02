# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/resources/types'

# Load types in dependency order
require_relative 'types/expiration'
require_relative 'types/transition'
require_relative 'types/filter'
require_relative 'types/rule'
require_relative 'types/attributes'

module Pangea
  module Resources
    module AWS
      module Types
        # LifecycleExpiration, LifecycleNoncurrentVersionExpiration are in types/expiration.rb
        # LifecycleTransition, LifecycleNoncurrentVersionTransition are in types/transition.rb
        # LifecycleFilterTag, LifecycleFilterAnd, LifecycleFilter are in types/filter.rb
        # LifecycleAbortIncompleteMultipartUpload, LifecycleRule are in types/rule.rb
        # S3BucketLifecycleConfigurationAttributes is in types/attributes.rb
      end
    end
  end
end
