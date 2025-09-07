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


module Pangea
  # Simple UI for outputting messages
  class UI
    def initialize(output = $stdout)
      @output = output
    end
    
    def say(message)
      @output.puts message
    end
    
    def info(message)
      @output.puts "[INFO] #{message}"
    end
    
    def success(message)
      @output.puts "[✓] #{message}"
    end
    
    def warn(message)
      @output.puts "[WARNING] #{message}"
    end
    
    def error(message)
      @output.puts "[ERROR] #{message}"
    end
  end
end