# AWS Athena Named Query - Technical Documentation

## Architecture Overview

AWS Athena Named Queries provide a mechanism to save, organize, and share SQL queries within a workgroup. They act as query templates that can be parameterized and reused, promoting consistency and reducing errors in analytical workflows.

### Key Concepts

1. **Query Templates**: Reusable SQL with parameters
2. **Workgroup Isolation**: Queries saved per workgroup
3. **Version Control**: Track query changes over time
4. **Team Collaboration**: Share standardized queries

## Implementation Details

### Type Safety with Dry::Struct

The `AthenaNamedQueryAttributes` class provides comprehensive validation:

```ruby
# Query validation
- Name limited to 128 characters
- Query must not be empty
- Query size limited to 256KB (Athena limit)
- Must start with valid SQL statement
- Basic SQL syntax validation

# Supported SQL statements
- SELECT (including WITH clauses)
- INSERT INTO
- CREATE TABLE/VIEW/DATABASE
- ALTER TABLE
- DROP TABLE/VIEW/DATABASE
- MSCK REPAIR TABLE
- SHOW/DESCRIBE
```

### Resource Outputs

The resource returns these Terraform outputs:
- `id` - Named query ID (UUID format)

### Computed Properties

1. **Query Classification**
   - `is_select_query?` - Read-only query check
   - `is_ddl_query?` - Schema modification check
   - `is_insert_query?` - Data modification check
   - `is_maintenance_query?` - Table maintenance check
   - `query_type` - Specific query classification

2. **Query Analysis**
   - `referenced_tables` - Tables used in query
   - `uses_partitions?` - Partition filtering detection
   - `uses_aggregations?` - Aggregate function usage
   - `uses_window_functions?` - Window function usage
   - `query_complexity_score` - Cost estimation metric

3. **Query Utilities**
   - `parameterized_query` - Template with parameters
   - `generate_documentation` - Auto-generated docs

## Advanced Features

### Query Complexity Scoring

The complexity score helps estimate query cost and performance:

```ruby
# Base score: 1.0
# Multipliers:
- Aggregations: 1.5x
- Window functions: 2.0x
- JOINs: 1.2x + 0.1x per additional JOIN
- DISTINCT: 1.3x
- ORDER BY: 1.4x
- Partitions: 0.7x (reduces cost)

# Example scores:
- Simple SELECT: 1.0
- SELECT with GROUP BY: 1.5
- Complex JOIN with window functions: 3.6
- Partitioned aggregate query: 1.05
```

### Table Reference Extraction

Automatically extracts table references for dependency tracking:

```ruby
# Supports various SQL patterns:
- Fully qualified: database.table
- With quotes: `database`.`table`
- From FROM clause
- From JOIN clauses
- Handles subqueries
```

### Query Parameterization

Converts hardcoded values to parameters:

```ruby
# Original query:
SELECT * FROM orders 
WHERE date = '2024-01-15' 
AND customer_id = 12345

# Parameterized:
SELECT * FROM orders 
WHERE date = '${date_param}' 
AND customer_id = ${id_param}
```

## Best Practices

### 1. Query Organization

```ruby
# Group by function
[:reporting, :etl, :monitoring, :adhoc].each do |category|
  aws_athena_named_query(:"#{category}_template", {
    name: "#{category.capitalize} Query Template",
    database: "default",
    query: "SELECT 1", # Replace with actual template
    workgroup: "#{category}-workgroup"
  })
end
```

### 2. Performance Optimization

```ruby
# Always use partitions when available
aws_athena_named_query(:optimized_query, {
  name: "Partitioned Query",
  database: "analytics",
  query: <<~SQL
    SELECT * 
    FROM large_table
    WHERE year = ${year}
    AND month = ${month}
    AND day = ${day}
    -- Partition columns first for pruning
  SQL
})

# Use approximate functions for large datasets
aws_athena_named_query(:approx_query, {
  name: "Approximate Analytics",
  database: "analytics",
  query: <<~SQL
    SELECT 
      approx_distinct(user_id) as unique_users,
      approx_percentile(revenue, 0.5) as median_revenue
    FROM transactions
    WHERE date >= current_date - interval '7' day
  SQL
})
```

### 3. Query Templates

```ruby
# Create reusable templates
class QueryTemplates
  def self.partition_stats(table, partition_col)
    <<~SQL
      SELECT 
        #{partition_col},
        COUNT(*) as row_count,
        SUM(size) / 1073741824.0 as size_gb
      FROM "#{table}$partitions"
      GROUP BY #{partition_col}
      ORDER BY #{partition_col} DESC
    SQL
  end
  
  def self.data_freshness(table, timestamp_col)
    <<~SQL
      SELECT 
        MAX(#{timestamp_col}) as latest_record,
        CURRENT_TIMESTAMP - MAX(#{timestamp_col}) as data_lag
      FROM #{table}
    SQL
  end
end
```

## Common Patterns

### 1. Business Metrics Library

```ruby
business_metrics = {
  mrr: "Monthly Recurring Revenue",
  churn: "Customer Churn Rate",
  ltv: "Customer Lifetime Value",
  cac: "Customer Acquisition Cost"
}

business_metrics.each do |metric, description|
  aws_athena_named_query(:"business_#{metric}", {
    name: description,
    database: "business_metrics",
    query: File.read("queries/business/#{metric}.sql"),
    description: "Calculate #{description}",
    workgroup: "finance"
  })
end
```

### 2. Data Quality Checks

```ruby
tables_to_check = ["users", "orders", "products"]

tables_to_check.each do |table|
  aws_athena_named_query(:"quality_#{table}", {
    name: "Data Quality - #{table}",
    database: "raw_data",
    query: <<~SQL
      WITH quality_metrics AS (
        SELECT 
          COUNT(*) as total_rows,
          SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) as null_ids,
          COUNT(DISTINCT id) as unique_ids,
          MAX(updated_at) as last_update
        FROM #{table}
      )
      SELECT 
        *,
        CASE 
          WHEN null_ids > 0 THEN 'FAIL: NULL IDs found'
          WHEN unique_ids < total_rows THEN 'FAIL: Duplicate IDs'
          WHEN last_update < CURRENT_DATE - INTERVAL '1' DAY THEN 'WARN: Stale data'
          ELSE 'PASS'
        END as quality_status
      FROM quality_metrics
    SQL
  })
end
```

### 3. Cost Optimization Queries

```ruby
aws_athena_named_query(:cost_by_query, {
  name: "Query Cost Analysis",
  database: "default",
  query: <<~SQL
    SELECT 
      workgroup,
      DATE_TRUNC('day', start_time) as query_date,
      COUNT(*) as query_count,
      SUM(data_scanned_in_bytes) / 1099511627776.0 as total_tb_scanned,
      SUM(data_scanned_in_bytes) / 1099511627776.0 * 5 as estimated_cost_usd,
      AVG(engine_execution_time_in_millis) / 1000.0 as avg_execution_seconds
    FROM aws_cloudtrail_logs
    WHERE eventname = 'StartQueryExecution'
    AND start_time >= CURRENT_DATE - INTERVAL '30' DAY
    GROUP BY workgroup, DATE_TRUNC('day', start_time)
    ORDER BY estimated_cost_usd DESC
  SQL,
  workgroup: "admin"
})
```

## Integration Examples

### With Scheduled Queries

```ruby
# Create named query for scheduled execution
query_ref = aws_athena_named_query(:daily_rollup, {
  name: "Daily Data Rollup",
  database: "analytics",
  query: <<~SQL
    INSERT INTO daily_summaries
    SELECT 
      DATE_TRUNC('day', timestamp) as date,
      COUNT(*) as event_count,
      COUNT(DISTINCT user_id) as unique_users
    FROM events
    WHERE DATE_TRUNC('day', timestamp) = CURRENT_DATE - INTERVAL '1' DAY
    GROUP BY DATE_TRUNC('day', timestamp)
  SQL
})

# Reference in scheduled query
aws_cloudwatch_event_rule(:daily_rollup_schedule, {
  schedule_expression: "cron(0 2 * * ? *)",
  targets: [{
    arn: "arn:aws:athena:region:account:workgroup/scheduled",
    role_arn: role_ref.arn,
    input: JSON.generate({
      QueryExecutionContext: { Database: "analytics" },
      QueryString: query_ref.resource_attributes[:query]
    })
  }]
})
```

### With Lambda Functions

```ruby
# Named query for Lambda to execute
query_ref = aws_athena_named_query(:user_report, {
  name: "User Activity Report",
  database: "analytics",
  query: "SELECT * FROM user_activity WHERE user_id = '${user_id}' AND date >= '${start_date}'"
})

# Lambda function that executes the query
aws_lambda_function(:execute_report, {
  function_name: "execute-user-report",
  environment: {
    variables: {
      NAMED_QUERY_ID: query_ref.outputs[:id],
      OUTPUT_BUCKET: "s3://reports-bucket"
    }
  }
})
```

## Troubleshooting

### Common Issues

1. **Query Syntax Errors**
   - Validate SQL syntax before saving
   - Test queries in Athena console first
   - Check for missing quotes or parentheses

2. **Permission Issues**
   - Verify workgroup access permissions
   - Check database and table permissions
   - Ensure S3 access for referenced data

3. **Performance Problems**
   - Add partition filters
   - Use columnar formats (Parquet/ORC)
   - Limit data scanned with WHERE clauses

## Query Optimization Tips

1. **Partition Pruning**
```sql
-- Good: Partition columns first
WHERE year = 2024 AND month = 1 AND user_id = 123

-- Bad: Non-partition columns first  
WHERE user_id = 123 AND year = 2024 AND month = 1
```

2. **Join Optimization**
```sql
-- Good: Filter before join
WITH filtered_users AS (
  SELECT * FROM users WHERE created_date >= '2024-01-01'
)
SELECT * FROM orders o
JOIN filtered_users u ON o.user_id = u.id

-- Bad: Filter after join
SELECT * FROM orders o
JOIN users u ON o.user_id = u.id
WHERE u.created_date >= '2024-01-01'
```

3. **Aggregation Efficiency**
```sql
-- Good: Aggregate early
WITH daily_totals AS (
  SELECT date, SUM(amount) as total
  FROM transactions
  GROUP BY date
)
SELECT AVG(total) FROM daily_totals

-- Bad: Aggregate late
SELECT AVG(daily_total) FROM (
  SELECT date, amount FROM transactions
) GROUP BY date
```