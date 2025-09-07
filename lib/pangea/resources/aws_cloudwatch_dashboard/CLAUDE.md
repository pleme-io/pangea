# AWS CloudWatch Dashboard Implementation

## Overview

This implementation provides type-safe AWS CloudWatch Dashboard resources with comprehensive widget validation, JSON schema enforcement, and enterprise monitoring patterns.

## Architecture

### Type System Hierarchy
- **`CloudWatchDashboardAttributes`**: Main dashboard configuration with validation
- **`DashboardWidget`**: Individual widget configuration with layout validation  
- **`DashboardWidgetProperties`**: Type-specific widget properties
- **`DashboardMetric`**: Metric specification for metric widgets

### Key Features

#### 1. Multiple Configuration Methods
- **Raw JSON**: Direct `dashboard_body_json` string for maximum flexibility
- **Structured Hash**: `dashboard_body` hash that gets converted to JSON
- **Type-Safe Widgets**: `widgets` array with full validation and type safety

#### 2. Comprehensive Widget Validation
- **Layout Validation**: Prevents widget overlaps in 24-column grid
- **Type-Specific Validation**: Ensures required properties for each widget type
- **Dimension Constraints**: Validates grid positioning and sizing

#### 3. Widget Type Support
- **Metric Widgets**: Time series, single value, pie charts, bar charts
- **Text Widgets**: Markdown documentation and annotations
- **Log Widgets**: CloudWatch Logs Insights integration
- **Number Widgets**: Single metric value display
- **Explorer Widgets**: Metric explorer integration

#### 4. Enterprise Dashboard Patterns
- Application performance monitoring
- Infrastructure health monitoring
- Microservices observability
- Security and compliance dashboards

## Implementation Details

### Dashboard Name Validation
```ruby
# CloudWatch dashboard name constraints
name.match?(/\A[a-zA-Z0-9_\-\.]+\z/)  # Alphanumeric + underscore, hyphen, period
name.length <= 255                      # Maximum length
!name.empty?                           # Cannot be empty
```

### Configuration Method Validation
```ruby
# Exactly one configuration method required
body_provided = !dashboard_body.nil?
body_json_provided = !dashboard_body_json.nil?
widgets_provided = widgets && !widgets.empty?

provided_count = [body_provided, body_json_provided, widgets_provided].count(true)

# Must provide exactly one method
raise error if provided_count != 1
```

### Widget Overlap Detection
```ruby
def self.validate_widget_overlaps(widgets)
  occupied_positions = Set.new
  
  widgets.each_with_index do |widget, index|
    (widget[:x]...(widget[:x] + widget[:width])).each do |x|
      (widget[:y]...(widget[:y] + widget[:height])).each do |y|
        position = "#{x},#{y}"
        if occupied_positions.include?(position)
          raise Dry::Struct::Error, "Widget overlap at position (#{x}, #{y})"
        end
        occupied_positions.add(position)
      end
    end
  end
end
```

### Widget Type-Specific Validation
```ruby
case widget_type
when 'metric', 'number', 'explorer'
  # Requires metrics array or query
  validate_metric_configuration(properties)
when 'text'
  # Requires markdown content
  validate_text_configuration(properties)
when 'log'
  # Requires query and source
  validate_log_configuration(properties)
end
```

### Dashboard Body Generation
```ruby
def generate_dashboard_body
  return dashboard_body if dashboard_body
  return JSON.parse(dashboard_body_json) if dashboard_body_json
  return nil if widgets.nil?
  
  {
    widgets: widgets.map(&:to_h)
  }
end
```

### Cost Estimation
```ruby
def estimated_monthly_cost_usd
  # AWS CloudWatch dashboard pricing
  3.00  # $3 per dashboard per month (first 3 dashboards free per account)
end
```

### Computed Properties

1. **`widget_count`**: Integer count of widgets in dashboard
2. **`has_custom_body?`**: Boolean indicating custom JSON body usage
3. **`uses_widgets?`**: Boolean indicating structured widget configuration
4. **`dashboard_grid_height`**: Integer representing total grid height
5. **`estimated_monthly_cost_usd`**: Float cost estimation

### Terraform Resource Mapping
```ruby
resource(:aws_cloudwatch_dashboard, name) do
  dashboard_name dashboard_attrs.dashboard_name
  dashboard_body dashboard_attrs.to_h[:dashboard_body]  # JSON string
end
```

### Resource Reference Outputs
```ruby
outputs: {
  dashboard_arn: "${aws_cloudwatch_dashboard.#{name}.dashboard_arn}",
  dashboard_name: "${aws_cloudwatch_dashboard.#{name}.dashboard_name}"
}
```

## Widget System Design

### Widget Layout Grid System
- **Grid Width**: 24 columns
- **Grid Height**: Unlimited rows
- **Position**: (x, y) coordinates with (0, 0) at top-left
- **Size**: Width and height in grid units
- **Validation**: Prevents overlaps and ensures grid boundaries

### Widget Type Implementations

#### Metric Widget
```ruby
{
  type: "metric",
  properties: {
    metrics: [["Namespace", "MetricName", "DimensionKey", "DimensionValue"]],
    view: "timeSeries",        # timeSeries, singleValue, pie, bar, number
    period: 300,               # Seconds (minimum 60)
    stat: "Average",           # Average, Sum, Maximum, etc.
    region: "us-east-1",       # AWS region
    title: "Widget Title",     # Display title
    yaxis: { left: { min: 0, max: 100 } }  # Y-axis configuration
  }
}
```

#### Text Widget
```ruby
{
  type: "text",
  properties: {
    markdown: "# Title\\n\\nMarkdown content here"
  }
}
```

#### Log Widget
```ruby
{
  type: "log",
  properties: {
    query: "fields @timestamp, @message | limit 20",  # Logs Insights query
    source: "/aws/lambda/function-name",              # Log group
    title: "Recent Logs"
  }
}
```

### Metric Specification Format
```ruby
class DashboardMetric < Dry::Struct
  attribute :namespace, Resources::Types::String      # AWS/EC2, AWS/ECS, etc.
  attribute :metric_name, Resources::Types::String   # CPUUtilization, RequestCount
  attribute :dimensions, Resources::Types::Hash       # Key-value dimension pairs
  attribute :stat, Resources::Types::String          # Average, Sum, etc.
  attribute :period, Resources::Types::Integer        # Time period in seconds
  attribute :region, Resources::Types::String.optional
  attribute :label, Resources::Types::String.optional
end
```

## Enterprise Dashboard Patterns

### 1. Application Performance Monitoring (APM)
- Request volume and error rates
- Response time percentiles  
- Database performance metrics
- Application log analysis
- Service dependency health

### 2. Infrastructure Health Monitoring
- CPU, memory, and disk utilization
- Network I/O and throughput
- System-level metrics
- Capacity planning indicators
- Instance and service counts

### 3. Microservices Observability
- Per-service resource utilization
- Inter-service communication metrics
- Service mesh performance
- Distributed tracing insights
- Service dependency mapping

### 4. Security and Compliance Monitoring
- Authentication failure rates
- WAF blocked requests
- CloudTrail security events
- Compliance metric tracking
- Threat detection indicators

### 5. Business Intelligence Dashboards
- Revenue and transaction metrics
- User engagement metrics
- Conversion funnel analysis
- Geographic usage patterns
- Business KPI tracking

## Dashboard Design Patterns

### 1. Hierarchical Information Layout
```ruby
# Top: Summary/overview widgets
# Middle: Detailed metric time series
# Bottom: Log analysis and troubleshooting
```

### 2. Service-Oriented Organization
```ruby
# Column 1: Service A metrics
# Column 2: Service B metrics  
# Column 3: Cross-service metrics
```

### 3. Problem Detection Flow
```ruby
# Row 1: High-level health indicators
# Row 2: Drill-down diagnostic metrics
# Row 3: Root cause analysis tools
```

### 4. Time-Series Correlation
```ruby
# Aligned time series for cause-effect analysis
# Consistent time ranges across related widgets
# Synchronized zoom and pan capabilities
```

## Validation Error Categories

### Layout Validation Errors
- Widget position exceeds grid boundaries
- Widget overlap detection with position details
- Invalid widget dimensions or positioning

### Configuration Validation Errors
- Missing required properties for widget type
- Invalid widget type specification
- Malformed metric specifications

### JSON Validation Errors
- Invalid JSON syntax in dashboard_body_json
- Missing required JSON structure elements
- Type mismatches in JSON configuration

### Dashboard Validation Errors
- Invalid dashboard name patterns
- Missing configuration method
- Multiple configuration methods provided

## Performance Considerations

### Widget Performance
- Limit high-frequency metric queries
- Use appropriate aggregation periods
- Optimize log query performance
- Consider dashboard load times

### Cost Optimization
- Leverage free dashboard quota (first 3)
- Optimize log query data scanned
- Use efficient metric collection periods
- Monitor dashboard API call usage

### Scalability Patterns
- Template-based dashboard creation
- Parameterized dashboard generation
- Cross-region dashboard replication
- Automated dashboard lifecycle management

## Testing and Validation

### Unit Testing Support
- Deterministic computed property calculations
- Predictable validation error messages
- Type-safe widget configuration testing
- Dashboard body generation testing

### Integration Testing
- Widget layout validation testing
- JSON schema compliance testing
- AWS API compatibility testing
- Dashboard rendering validation

### Enterprise Testing Patterns
- Dashboard template testing
- Multi-environment dashboard validation
- Automated dashboard deployment testing
- Dashboard performance regression testing

## Best Practices Encoded

1. **Grid System**: Enforced 24-column grid layout for consistency
2. **Widget Validation**: Type-specific property validation
3. **JSON Safety**: Schema validation for manual JSON configuration
4. **Cost Awareness**: Built-in cost estimation and optimization guidance
5. **Enterprise Patterns**: Pre-built patterns for common use cases
6. **Documentation**: Text widget integration for dashboard documentation
7. **Accessibility**: Clear widget titles and descriptions
8. **Maintainability**: Structured configuration over raw JSON when possible