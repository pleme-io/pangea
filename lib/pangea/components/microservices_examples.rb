# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'microservices_examples/platform'
require_relative 'microservices_examples/saga'

module Pangea
  module Components
    # Example implementations showcasing advanced microservices components
    module MicroservicesExamples
      include Platform
      include Saga
    end
  end
end
