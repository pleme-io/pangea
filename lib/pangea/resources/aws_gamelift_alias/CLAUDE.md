# AWS GameLift Alias Resource - Technical Documentation

## Architecture
GameLift Alias provides a abstraction layer between game clients and fleets. This enables fleet updates without client-side changes and supports sophisticated deployment strategies.

## Core Concepts

### Routing Types
1. **SIMPLE**: Direct routing to a fleet
2. **TERMINAL**: Returns a message (maintenance mode)

### Alias Resolution
- Clients connect using alias ARN/ID
- GameLift resolves to current fleet
- Transparent to game clients

## Deployment Strategies

### Blue-Green Deployment
```ruby
# Initial setup - Blue fleet active
blue_fleet = aws_gamelift_fleet(:blue, {
  name: "blue-fleet",
  build_id: build_v1.id,
  # ... configuration
})

green_fleet = aws_gamelift_fleet(:green, {
  name: "green-fleet", 
  build_id: build_v2.id,
  # ... same configuration
})

production_alias = aws_gamelift_alias(:production, {
  name: "production-endpoint",
  description: "Main game endpoint",
  routing_strategy: {
    type: "SIMPLE",
    fleet_id: blue_fleet.id  # Currently on blue
  }
})

# During deployment - Switch to green
# This would be done via Terraform apply after testing
```

### Canary Deployment
```ruby
# Multiple aliases for different player segments
aws_gamelift_alias(:stable, {
  name: "stable-players",
  description: "99% of players",
  routing_strategy: {
    type: "SIMPLE",
    fleet_id: stable_fleet.id
  }
})

aws_gamelift_alias(:canary, {
  name: "canary-players",
  description: "1% early adopters",
  routing_strategy: {
    type: "SIMPLE",
    fleet_id: canary_fleet.id
  }
})
```

### Maintenance Mode
```ruby
# Quick maintenance toggle
aws_gamelift_alias(:game_service, {
  name: "game-service",
  description: "Primary game endpoint",
  routing_strategy: {
    type: var.maintenance_mode ? "TERMINAL" : "SIMPLE",
    fleet_id: var.maintenance_mode ? null : fleet.id,
    message: var.maintenance_mode ? "Scheduled maintenance until 2 PM PST" : null
  }
})
```

## Multi-Region Architecture

### Regional Aliases
```ruby
regions = ["us-east-1", "eu-west-1", "ap-southeast-1"]

regions.each do |region|
  # Fleet per region
  fleet = aws_gamelift_fleet(:"fleet_#{region}", {
    name: "game-fleet-#{region}",
    # ... region-specific config
  })
  
  # Alias per region
  aws_gamelift_alias(:"alias_#{region}", {
    name: "game-alias-#{region}",
    description: "Game endpoint for #{region}",
    routing_strategy: {
      type: "SIMPLE",
      fleet_id: fleet.id
    }
  })
end
```

### Global Game Session Queue
```ruby
# Use aliases in session queue for global matchmaking
aws_gamelift_game_session_queue(:global_queue, {
  name: "global-game-queue",
  destinations: regions.map { |r| 
    ref(:aws_gamelift_alias, :"alias_#{r}", :arn)
  }
})
```

## Client Integration

### Connection String Format
```
gamelift://<alias-id>.<region>.amazonaws.com
```

### SDK Integration
```ruby
# Game client pseudocode
class GameClient
  def connect_to_game
    alias_id = ENV['GAMELIFT_ALIAS_ID']
    session = gamelift.create_game_session(
      alias_id: alias_id,
      maximum_player_session_count: 10
    )
  end
end
```

## Monitoring and Metrics

### Alias-Level Metrics
```ruby
aws_cloudwatch_metric_alarm(:alias_connection_failures, {
  alarm_name: "gamelift-alias-failures",
  metric_name: "ConnectionFailures",
  namespace: "AWS/GameLift",
  dimensions: [{
    name: "AliasId",
    value: production_alias.id
  }],
  threshold: 10
})
```

### Health Checks
- Monitor alias resolution time
- Track routing failures
- Alert on TERMINAL transitions

## Security Considerations

### IAM Permissions
```ruby
# Client access policy
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "gamelift:CreateGameSession",
      "gamelift:CreatePlayerSession"
    ],
    "Resource": "arn:aws:gamelift:*:*:alias/*"
  }]
}
```

### Access Control
- Aliases can be region-specific
- Support resource-based policies
- Integrate with AWS PrivateLink

## Advanced Patterns

### A/B Testing
```ruby
# Feature flag based routing
feature_enabled = aws_ssm_parameter(:feature_flag, {
  name: "/gamelift/new-feature-enabled",
  type: "String",
  value: "false"
})

aws_gamelift_alias(:dynamic_routing, {
  name: "ab-test-endpoint",
  description: "A/B test routing",
  routing_strategy: {
    type: "SIMPLE",
    fleet_id: feature_enabled.value == "true" ? 
      new_feature_fleet.id : 
      stable_fleet.id
  }
})
```

### Disaster Recovery
```ruby
# Primary and DR aliases
aws_gamelift_alias(:primary, {
  name: "primary-endpoint",
  description: "Primary region endpoint",
  routing_strategy: {
    type: "SIMPLE",
    fleet_id: primary_fleet.id
  }
})

aws_gamelift_alias(:disaster_recovery, {
  name: "dr-endpoint",
  description: "Disaster recovery endpoint",
  routing_strategy: {
    type: health_check_passing ? "TERMINAL" : "SIMPLE",
    fleet_id: health_check_passing ? null : dr_fleet.id,
    message: health_check_passing ? 
      "Primary region healthy - use primary endpoint" : null
  }
})
```

## Best Practices

### Naming Conventions
- Use environment prefixes: prod-, dev-, staging-
- Include region in multi-region setups
- Version aliases for major releases

### Update Strategy
1. Always test new fleet before alias update
2. Monitor metrics during transition
3. Keep old fleet running during validation
4. Have rollback plan ready

### Cost Optimization
- Reuse aliases across environments
- Implement scheduled scaling via alias updates
- Use TERMINAL during off-hours

## Troubleshooting

### Common Issues
1. **Connection Timeout**: Check fleet status
2. **Invalid Alias**: Verify alias exists in region
3. **Routing Failures**: Check fleet capacity
4. **Resolution Errors**: Validate IAM permissions

### Debug Steps
1. Check alias routing configuration
2. Verify fleet is ACTIVE
3. Test direct fleet connection
4. Review CloudWatch logs