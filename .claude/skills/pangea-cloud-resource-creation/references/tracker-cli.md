# Tracker Management CLI

Implementation for tracking resource completion across batches.

## CLI Script Template

**Location**: `bin/{provider}-tracker`

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'date'

TRACKER_FILE = File.join(__dir__, '..', 'PROVIDER_IMPLEMENTATION.json')

def load_tracker
  JSON.parse(File.read(TRACKER_FILE), symbolize_names: true)
end

def save_tracker(data)
  File.write(TRACKER_FILE, JSON.pretty_generate(data))
  puts "Tracker saved"
end

def update_completion(data)
  total = data[:metadata][:total_resources]
  implemented = data[:resources].values.count { |r|
    r[:components][:types] && r[:components][:resource] && r[:components][:spec]
  }
  data[:metadata][:implemented] = implemented
  data[:metadata][:completion_percentage] = (implemented.to_f / total * 100).round(1)
  data[:metadata][:last_updated] = Date.today.to_s
end

command = ARGV[0]
case command
when 'status'
  data = load_tracker
  puts "#{data[:metadata][:provider]} Implementation Status"
  puts "=" * 60
  puts "Total: #{data[:metadata][:total_resources]}"
  puts "Implemented: #{data[:metadata][:implemented]} (#{data[:metadata][:completion_percentage]}%)"

when 'update'
  resource = ARGV[1]
  component = ARGV[2] # 'types', 'resource', 'spec', 'all'

  data = load_tracker
  if component == 'all'
    data[:resources][resource.to_sym][:components][:types] = true
    data[:resources][resource.to_sym][:components][:resource] = true
    data[:resources][resource.to_sym][:components][:spec] = true
    puts "Marked all components of #{resource} as complete"
  else
    data[:resources][resource.to_sym][:components][component.to_sym] = true
    puts "Marked #{component} of #{resource} as complete"
  end

  update_completion(data)
  save_tracker(data)
end
```

## Usage

```bash
# Check status
bin/hetzner-tracker status

# Mark single component complete
bin/hetzner-tracker update hcloud_volume types

# Mark all components complete
bin/hetzner-tracker update hcloud_volume all
```
