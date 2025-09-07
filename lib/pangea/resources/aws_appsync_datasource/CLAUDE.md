# AWS AppSync DataSource - Developer Guide

## Overview

The `aws_appsync_datasource` resource connects AWS AppSync GraphQL APIs to backend data sources. AppSync supports multiple data source types, each optimized for different use cases and workloads.

## Data Source Types and Use Cases

### 1. DynamoDB Data Sources
Best for: NoSQL data, real-time applications, serverless architectures

```ruby
# Standard DynamoDB data source
datasource = aws_appsync_datasource(:users_table, {
  api_id: api.id,
  name: "UsersTable",
  type: "AMAZON_DYNAMODB",
  dynamodb_config: {
    table_name: users_table.name,
    region: "us-east-1",
    use_caller_credentials: false,  # Use service role
    versioned: true  # Enable conflict detection
  },
  service_role_arn: dynamodb_role.arn
})
```

#### Conflict Detection with Versioning
When `versioned: true`, AppSync adds version tracking to enable optimistic concurrency:

```ruby
# Mutation resolver will include version checks
# mutation updateUser($id: ID!, $input: UpdateUserInput!, $_version: Int!) {
#   updateUser(id: $id, input: $input, _version: $_version) {
#     id
#     name
#     _version
#   }
# }
```

#### Delta Sync for Offline Support
Enable incremental sync for mobile/offline applications:

```ruby
datasource = aws_appsync_datasource(:sync_table, {
  api_id: api.id,
  name: "SyncTable",
  type: "AMAZON_DYNAMODB",
  dynamodb_config: {
    table_name: base_table.name,
    versioned: true,
    delta_sync_config: {
      base_table_ttl: 1440,  # 24 hours
      delta_sync_table_name: delta_table.name,
      delta_sync_table_ttl: 60  # 1 hour
    }
  },
  service_role_arn: sync_role.arn
})
```

### 2. Lambda Data Sources
Best for: Business logic, external API integration, data transformation

```ruby
# Lambda for complex business logic
datasource = aws_appsync_datasource(:business_logic, {
  api_id: api.id,
  name: "BusinessLogic",
  type: "AWS_LAMBDA",
  lambda_config: {
    function_arn: lambda_function.arn
  },
  service_role_arn: lambda_role.arn
})
```

#### Lambda Function Event Structure
AppSync sends a specific event structure to Lambda functions:

```json
{
  "field": "getUser",
  "arguments": {
    "id": "123"
  },
  "identity": {
    "claims": {...},
    "sourceIp": ["192.168.1.1"]
  },
  "request": {
    "headers": {...}
  }
}
```

### 3. HTTP Data Sources
Best for: REST API integration, third-party services, microservices

```ruby
# External REST API integration
datasource = aws_appsync_datasource(:rest_api, {
  api_id: api.id,
  name: "ExternalAPI",
  type: "HTTP",
  http_config: {
    endpoint: "https://api.example.com",
    authorization_config: {
      authorization_type: "AWS_IAM",
      aws_iam_config: {
        signing_region: "us-east-1",
        signing_service_name: "execute-api"
      }
    }
  }
})
```

#### HTTP Request Mapping
Transform GraphQL requests to HTTP requests in resolvers:

```javascript
// Request mapping template
{
  "version": "2018-05-29",
  "method": "POST",
  "resourcePath": "/users/${context.arguments.id}",
  "params": {
    "headers": {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${context.request.headers.authorization}"
    },
    "body": $util.toJson($context.arguments.input)
  }
}
```

### 4. Relational Database Data Sources
Best for: Structured data, complex queries, existing RDS databases

```ruby
# Aurora Serverless with Data API
datasource = aws_appsync_datasource(:aurora_db, {
  api_id: api.id,
  name: "AuroraDatabase",
  type: "RELATIONAL_DATABASE",
  relational_database_config: {
    source_type: "RDS_HTTP_ENDPOINT",
    rds_http_endpoint_config: {
      aws_secret_store_arn: db_secret.arn,
      db_cluster_identifier: aurora_cluster.id,
      database_name: "myapp",
      region: "us-east-1",
      schema: "public"
    }
  },
  service_role_arn: rds_role.arn
})
```

#### SQL Query Templates
Execute SQL queries through resolvers:

```javascript
// Query with parameters
{
  "version": "2018-05-29",
  "statements": [
    "SELECT * FROM users WHERE id = :id",
    "SELECT * FROM orders WHERE user_id = :id"
  ],
  "variableMap": {
    ":id": $util.toJson($context.arguments.id)
  }
}
```

### 5. EventBridge Data Sources
Best for: Event-driven architectures, decoupled systems, async processing

```ruby
# Send events to EventBridge
datasource = aws_appsync_datasource(:events, {
  api_id: api.id,
  name: "EventBus",
  type: "AMAZON_EVENTBRIDGE",
  event_bridge_config: {
    event_bus_arn: custom_bus.arn
  },
  service_role_arn: eventbridge_role.arn
})
```

#### Event Publishing Pattern
```javascript
// Resolver template for publishing events
{
  "version": "2018-05-29",
  "operation": "PutEvents",
  "events": [
    {
      "source": "myapp.users",
      "detail-type": "User Created",
      "detail": $util.toJson({
        "userId": $context.result.id,
        "email": $context.result.email,
        "timestamp": $util.time.nowISO8601()
      })
    }
  ]
}
```

### 6. None Data Sources
Best for: Local resolvers, pipeline resolvers, data transformation

```ruby
# Local data source for pipeline resolvers
datasource = aws_appsync_datasource(:local, {
  api_id: api.id,
  name: "LocalDataSource",
  type: "NONE",
  description: "Local data source for pipeline resolvers"
})
```

## IAM Role Requirements

Each data source type requires specific IAM permissions:

### DynamoDB Permissions
```ruby
# Basic DynamoDB permissions
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem"
      ],
      "Resource": [
        "arn:aws:dynamodb:region:account:table/TableName",
        "arn:aws:dynamodb:region:account:table/TableName/*"
      ]
    }
  ]
}
```

### Lambda Permissions
```ruby
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": "arn:aws:lambda:region:account:function:FunctionName"
    }
  ]
}
```

### RDS Data API Permissions
```ruby
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rds-data:ExecuteStatement",
        "rds-data:BatchExecuteStatement",
        "rds-data:BeginTransaction",
        "rds-data:CommitTransaction",
        "rds-data:RollbackTransaction"
      ],
      "Resource": "arn:aws:rds:region:account:cluster:ClusterName"
    },
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:region:account:secret:SecretName"
    }
  ]
}
```

## Performance Optimization

### 1. Batch Operations
Use batch operations to reduce round trips:

```ruby
# DynamoDB batch resolver
{
  "version": "2018-05-29",
  "operation": "BatchGetItem",
  "tables": {
    "UsersTable": {
      "keys": $util.toJson($context.arguments.userIds),
      "consistentRead": true
    }
  }
}
```

### 2. Caching Strategy
Implement caching at the resolver level:

```ruby
# Resolver with caching (configured separately)
resolver = aws_appsync_resolver(:cached_query, {
  api_id: api.id,
  type: "Query",
  field: "getPopularItems",
  data_source: datasource.name,
  caching_config: {
    caching_keys: ["$context.arguments.category"],
    ttl: 300  # 5 minutes
  }
})
```

### 3. Connection Pooling
For HTTP data sources, AppSync manages connection pooling automatically. For Lambda, consider:

```ruby
# Lambda with connection pooling
const mysql = require('mysql2/promise');

// Connection pool created outside handler
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

exports.handler = async (event) => {
  const connection = await pool.getConnection();
  try {
    // Use connection
  } finally {
    connection.release();
  }
};
```

## Security Best Practices

### 1. Least Privilege Access
Grant only necessary permissions to service roles:

```ruby
# Minimal DynamoDB permissions
role_policy = aws_iam_role_policy(:minimal_dynamo, {
  role: service_role.id,
  policy: jsonencode({
    Version: "2012-10-17",
    Statement: [{
      Effect: "Allow",
      Action: [
        "dynamodb:GetItem",
        "dynamodb:Query"
      ],
      Resource: table.arn,
      Condition: {
        "ForAllValues:StringEquals": {
          "dynamodb:LeadingKeys": ["${dynamodb:userId}"]
        }
      }
    }]
  })
})
```

### 2. Encryption in Transit
All data sources support encryption in transit. For HTTP:

```ruby
datasource = aws_appsync_datasource(:secure_http, {
  api_id: api.id,
  name: "SecureHTTP",
  type: "HTTP",
  http_config: {
    endpoint: "https://api.example.com",  # HTTPS required
    # Additional TLS configuration handled by AppSync
  }
})
```

### 3. Secrets Management
Use AWS Secrets Manager for credentials:

```ruby
# RDS with Secrets Manager
datasource = aws_appsync_datasource(:secure_rds, {
  api_id: api.id,
  name: "SecureRDS",
  type: "RELATIONAL_DATABASE",
  relational_database_config: {
    rds_http_endpoint_config: {
      aws_secret_store_arn: secret.arn,  # Credentials in Secrets Manager
      db_cluster_identifier: cluster.id
    }
  },
  service_role_arn: role.arn
})
```

## Common Issues and Solutions

### Issue: DynamoDB Throttling
Solution: Implement exponential backoff and use on-demand billing:

```javascript
// Resolver with retry logic
{
  "version": "2018-05-29",
  "operation": "GetItem",
  "key": {
    "id": $util.dynamodb.toDynamoDBJson($ctx.args.id)
  },
  "consistentRead": false  // Eventually consistent reads reduce throttling
}
```

### Issue: Lambda Cold Starts
Solution: Use provisioned concurrency and connection pooling:

```ruby
lambda_function = aws_lambda_function(:warm_function, {
  # ... other config ...
  reserved_concurrent_executions: 10,
  provisioned_concurrent_executions: 5
})
```

### Issue: HTTP Timeout
Solution: Configure appropriate timeouts and implement retry logic:

```javascript
// HTTP resolver with timeout handling
{
  "version": "2018-05-29",
  "method": "POST",
  "resourcePath": "/api/data",
  "params": {
    "headers": {
      "Content-Type": "application/json",
      "X-Request-Timeout": "5000"  // 5 second timeout hint
    }
  }
}
```

## Data Source Selection Guide

Choose your data source based on:

1. **DynamoDB**: Real-time data, NoSQL patterns, mobile/offline sync
2. **Lambda**: Complex logic, external APIs, data transformation
3. **HTTP**: REST APIs, microservices, third-party integration
4. **RDS**: Relational data, complex queries, existing databases
5. **EventBridge**: Async processing, event-driven patterns
6. **None**: Local resolvers, pipeline orchestration