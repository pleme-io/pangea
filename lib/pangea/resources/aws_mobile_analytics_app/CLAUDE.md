# AWS Mobile Analytics App Resource - Technical Documentation

## ⚠️ DEPRECATION NOTICE
AWS Mobile Analytics was deprecated by Amazon in favor of Amazon Pinpoint. This resource is maintained solely for legacy infrastructure support. All new implementations should use Amazon Pinpoint.

## Historical Context

### Service Overview
AWS Mobile Analytics was Amazon's first-generation mobile app analytics service, launched in 2014. It provided:
- Basic usage metrics
- Custom event tracking
- User session analysis
- Revenue tracking
- Device and OS analytics

### Deprecation Timeline
- 2016: Amazon Pinpoint launched with Mobile Analytics features
- 2018: AWS stopped promoting Mobile Analytics
- 2021: Service entered maintenance mode
- Present: Legacy support only, no new features

## Migration Path

### From Mobile Analytics to Pinpoint
```ruby
# Legacy Mobile Analytics setup
aws_mobile_analytics_app(:old_analytics, {
  name: "GameApp-Analytics"
})

# Modern Pinpoint replacement
aws_pinpoint_app(:new_analytics, {
  name: "GameApp-Analytics-v2",
  tags: {
    Purpose: "analytics",
    MigratedFrom: "mobile-analytics",
    MigrationDate: Time.now.strftime("%Y-%m-%d")
  }
})

# Pinpoint event stream for analytics
aws_pinpoint_event_stream(:analytics_stream, {
  application_id: new_analytics.application_id,
  destination_stream_arn: kinesis_stream.arn,
  role_arn: analytics_role.arn
})
```

### Feature Mapping
| Mobile Analytics Feature | Pinpoint Equivalent |
|-------------------------|-------------------|
| App Opens | Session Start Events |
| Custom Events | Custom Events (Enhanced) |
| User Attributes | Endpoint Attributes |
| Revenue Events | Monetization Events |
| Daily/Monthly Active Users | Built-in Metrics |
| Retention Metrics | Engagement Metrics |

## Legacy Support Considerations

### Existing Infrastructure
```ruby
# Only use for existing apps that haven't migrated
aws_mobile_analytics_app(:legacy_support, {
  name: "LegacyGame-Analytics"
})

# Add migration tracking
aws_ssm_parameter(:migration_status, {
  name: "/mobile-analytics/migration-status/LegacyGame",
  type: "String",
  value: "pending-migration"
})
```

### Data Export Before Migration
```ruby
# Export historical data to S3
aws_s3_bucket(:analytics_archive, {
  bucket: "mobile-analytics-archive-${var.account_id}"
})

# Lambda to export data
aws_lambda_function(:export_analytics, {
  function_name: "export-mobile-analytics",
  description: "Export Mobile Analytics data before migration",
  environment: {
    variables: {
      ANALYTICS_APP_ID: legacy_app.id,
      ARCHIVE_BUCKET: analytics_archive.id
    }
  }
})
```

## SDK Considerations

### Legacy SDK Usage
```javascript
// Old Mobile Analytics SDK (deprecated)
var mobileAnalytics = new AWS.MobileAnalytics({
  appId: 'legacy-app-id'
});

// New Pinpoint SDK
var pinpoint = new AWS.Pinpoint({
  region: 'us-east-1'
});
```

### SDK Migration Steps
1. Update mobile app to latest AWS SDK
2. Replace Mobile Analytics calls with Pinpoint
3. Test event recording
4. Gradually phase out old SDK
5. Remove Mobile Analytics dependency

## Cost Implications

### Mobile Analytics Pricing (Historical)
- $1 per million events
- First 100 million events free per month
- No additional charges

### Pinpoint Pricing (Current)
- Similar event pricing
- Additional features may incur costs
- More flexible pricing tiers

## Data Retention

### Mobile Analytics Limitations
- 60-day data retention
- Limited export options
- No real-time streaming

### Pinpoint Advantages
- Configurable retention
- Real-time event streaming
- S3 export capabilities
- Integration with AWS analytics services

## Common Migration Issues

### 1. Event Schema Differences
```ruby
# Mobile Analytics event
{
  eventType: "level_complete",
  attributes: {
    level: "10",
    score: "5000"
  }
}

# Pinpoint event (richer schema)
{
  eventType: "level_complete",
  attributes: {
    level: "10",
    score: "5000"
  },
  metrics: {
    completion_time: 120.5,
    attempts: 3
  },
  session: {
    id: "session-123",
    start_time: "2024-01-01T10:00:00Z"
  }
}
```

### 2. API Compatibility
- Mobile Analytics API is deprecated
- No new API features
- Pinpoint API is actively developed

### 3. Dashboard Access
- Mobile Analytics console being phased out
- Limited reporting capabilities
- Pinpoint provides comprehensive dashboards

## Minimal Implementation

### Absolute Minimum for Legacy Support
```ruby
# Only if absolutely necessary
aws_mobile_analytics_app(:minimal_legacy, {
  name: "Required-Legacy-App"
})

# Document why it's still needed
aws_ssm_parameter(:legacy_reason, {
  name: "/mobile-analytics/legacy-reason/Required-Legacy-App",
  type: "String",
  value: "Cannot migrate due to: [specific reason]"
})
```

## Best Practices for Legacy Resources

### 1. Document Everything
```ruby
aws_mobile_analytics_app(:documented_legacy, {
  name: "Legacy-Analytics-2019"
})

# Create comprehensive documentation
aws_s3_object(:legacy_docs, {
  bucket: docs_bucket.id,
  key: "mobile-analytics/Legacy-Analytics-2019/README.md",
  content: <<-DOC
    # Legacy Mobile Analytics App
    
    ## Why This Still Exists
    - App version 1.x still in production
    - 5% of users on legacy version
    - Planned EOL: Q4 2024
    
    ## Migration Plan
    - Phase 1: Update SDK (Q2 2024)
    - Phase 2: Dual-write events (Q3 2024)
    - Phase 3: Cut over to Pinpoint (Q4 2024)
  DOC
})
```

### 2. Monitor Usage
```ruby
# Track if legacy app is still being used
aws_cloudwatch_metric_alarm(:legacy_usage, {
  alarm_name: "mobile-analytics-legacy-usage",
  alarm_description: "Alert if legacy Mobile Analytics still receiving events",
  comparison_operator: "GreaterThanThreshold",
  evaluation_periods: 1,
  threshold: 0
})
```

### 3. Plan Retirement
```ruby
# Set retirement date
aws_ssm_parameter(:retirement_date, {
  name: "/mobile-analytics/retirement-date",
  type: "String",
  value: "2024-12-31",
  description: "Target date for Mobile Analytics retirement"
})
```

## Conclusion

AWS Mobile Analytics should not be used for new projects. This resource exists purely for backwards compatibility with legacy infrastructure. All mobile analytics needs should be implemented using Amazon Pinpoint, which provides superior features, better SDK support, and active development.

For teams still using Mobile Analytics:
1. Create a migration plan immediately
2. Document why migration hasn't occurred
3. Set a firm retirement date
4. Begin testing with Pinpoint in parallel

The deprecation warning in the resource module serves as a constant reminder that migration is necessary.