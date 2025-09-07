# AWS GameLift Fleet Resource - Technical Documentation

## Architecture
GameLift Fleet is a core component of Amazon GameLift's game server hosting solution. It manages collections of EC2 instances that run game server processes, providing automatic scaling, health monitoring, and game session placement.

## Key Concepts

### Fleet Types
- **ON_DEMAND**: Stable pricing, guaranteed capacity
- **SPOT**: Cost-effective, potential interruptions

### Compute Types
- **EC2**: Traditional EC2-based fleets
- **ANYWHERE**: Hybrid deployments using on-premises hardware

### Build vs Script
- **Build**: Custom game server executables (C++, C#, etc.)
- **Script**: Realtime Servers using Node.js/JavaScript

## Implementation Details

### Type Validation
The types.rb file implements comprehensive validation:
- Either build_id or script_id required (mutually exclusive)
- IP permissions validate port ranges and protocols
- Runtime configuration validates server process settings
- Scaling constraints ensure min <= desired <= max

### Resource Defaults
- fleet_type: ON_DEMAND (stable hosting)
- new_game_session_protection_policy: NoProtection
- certificate_configuration: GENERATED (automatic TLS)
- Scaling: min=0, max=1, desired=1

### Computed Attributes
- id: Fleet identifier
- arn: Fleet ARN for IAM policies
- build_arn: Associated build ARN
- status: Fleet status (ACTIVE, BUILDING, etc.)
- log_paths: S3 paths for game session logs

## Game Server Architecture Patterns

### Multi-Region Deployment
```ruby
["us-east-1", "eu-west-1", "ap-northeast-1"].each do |region|
  aws_gamelift_fleet(:"game_fleet_#{region}", {
    name: "game-fleet-#{region}",
    build_id: ref(:aws_gamelift_build, :"game_build_#{region}", :id),
    ec2_instance_type: "c5.large",
    min_size: 2,
    max_size: 20,
    desired_ec2_instances: 4
  })
end
```

### Development vs Production
```ruby
# Development fleet - minimal resources
aws_gamelift_fleet(:dev_fleet, {
  name: "dev-game-fleet",
  build_id: dev_build_id,
  ec2_instance_type: "t3.medium",
  fleet_type: "SPOT",
  max_size: 2
})

# Production fleet - high availability
aws_gamelift_fleet(:prod_fleet, {
  name: "prod-game-fleet",
  build_id: prod_build_id,
  ec2_instance_type: "c5.xlarge",
  fleet_type: "ON_DEMAND",
  min_size: 10,
  max_size: 100,
  new_game_session_protection_policy: "FullProtection"
})
```

## Security Considerations

### Network Security
- Configure minimal ec2_inbound_permission rules
- Use specific IP ranges instead of 0.0.0.0/0
- Separate game traffic from management ports

### TLS Configuration
- GENERATED: Automatic TLS certificates
- DISABLED: For development/testing only

### IAM Roles
- instance_role_arn grants permissions to fleet instances
- Required for S3 access, CloudWatch logs, etc.

## Performance Optimization

### Instance Selection
- c5 family: CPU-intensive games
- m5 family: Balanced workloads
- t3 family: Development/testing

### Process Configuration
```ruby
runtime_configuration: {
  game_session_activation_timeout_seconds: 300,
  max_concurrent_game_session_activations: 2,
  server_process: [
    {
      concurrent_executions: 10,  # Sessions per instance
      launch_path: "/game/server",
      parameters: "-maxplayers 100"
    }
  ]
}
```

## Monitoring and Metrics

### CloudWatch Integration
```ruby
metric_groups: ["default", "custom-metrics"],
```

### Key Metrics
- ActiveInstances
- IdleInstances
- PercentIdleInstances
- ActiveGameSessions
- GameSessionActivations

## Cost Management

### Spot Fleet Strategy
```ruby
aws_gamelift_fleet(:cost_optimized, {
  fleet_type: "SPOT",
  # Implement graceful shutdown in game server
  new_game_session_protection_policy: "FullProtection",
  # Scale down during off-peak
  min_size: 0
})
```

### Resource Limits
```ruby
resource_creation_limit_policy: {
  new_game_sessions_per_creator: 5,
  policy_period_in_minutes: 15
}
```

## Integration Points

### With GameLift Build
```ruby
build = aws_gamelift_build(:game_build, {...})
fleet = aws_gamelift_fleet(:game_fleet, {
  build_id: build.id,
  ...
})
```

### With GameLift Alias
```ruby
fleet = aws_gamelift_fleet(:blue_fleet, {...})
alias = aws_gamelift_alias(:production, {
  routing_strategy: {
    type: "SIMPLE",
    fleet_id: fleet.id
  }
})
```

### With Session Queue
```ruby
queue = aws_gamelift_game_session_queue(:matchmaking, {
  destinations: [fleet.arn]
})
```

## Troubleshooting

### Common Issues
1. Fleet stuck in ACTIVATING: Check build/script validity
2. No available instances: Verify scaling settings
3. Connection timeouts: Check security group rules
4. High latency: Review instance placement and types

### Health Checks
GameLift automatically performs health checks on fleet instances and replaces unhealthy ones.