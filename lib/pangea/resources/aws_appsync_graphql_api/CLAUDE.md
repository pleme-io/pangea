# AWS AppSync GraphQL API - Developer Guide

## Overview

The `aws_appsync_graphql_api` resource creates and manages AWS AppSync GraphQL APIs, providing a fully managed service that makes it easy to develop GraphQL APIs by handling the heavy lifting of securely connecting to data sources.

## Authentication Architecture

AppSync supports multiple authentication mechanisms that can be used individually or in combination:

### Primary Authentication Types
- **API_KEY**: Simple API key-based authentication for public APIs or development
- **AWS_IAM**: AWS Signature Version 4 signing for service-to-service communication
- **AMAZON_COGNITO_USER_POOLS**: User authentication via Cognito User Pools
- **OPENID_CONNECT**: Third-party identity provider integration
- **AWS_LAMBDA**: Custom authentication logic via Lambda functions

### Multiple Authentication Support
AppSync allows configuring additional authentication providers alongside the primary one, enabling flexible authentication strategies:

```ruby
# API with multiple auth methods for different use cases
api = aws_appsync_graphql_api(:flexible_api, {
  name: "FlexibleAPI",
  authentication_type: "API_KEY",  # Public queries
  additional_authentication_providers: [
    {
      authentication_type: "AMAZON_COGNITO_USER_POOLS",  # Authenticated mutations
      user_pool_config: {
        user_pool_id: cognito_pool.id,
        aws_region: "us-east-1"
      }
    },
    {
      authentication_type: "AWS_IAM"  # Service-to-service calls
    }
  ]
})
```

## Schema Management

GraphQL schemas define the API's data model and operations:

```ruby
schema_definition = <<-GRAPHQL
  type Query {
    getPost(id: ID!): Post
    listPosts(limit: Int, nextToken: String): PostConnection
  }
  
  type Mutation {
    createPost(input: CreatePostInput!): Post
    updatePost(id: ID!, input: UpdatePostInput!): Post
    deletePost(id: ID!): Post
  }
  
  type Subscription {
    onCreatePost: Post
      @aws_subscribe(mutations: ["createPost"])
    onUpdatePost(id: ID!): Post
      @aws_subscribe(mutations: ["updatePost"])
  }
  
  type Post {
    id: ID!
    title: String!
    content: String!
    author: User!
    createdAt: AWSDateTime!
    updatedAt: AWSDateTime!
  }
  
  type User {
    id: ID!
    name: String!
    email: String!
    posts: [Post!]!
  }
  
  input CreatePostInput {
    title: String!
    content: String!
    authorId: ID!
  }
  
  input UpdatePostInput {
    title: String
    content: String
  }
  
  type PostConnection {
    items: [Post!]!
    nextToken: String
  }
  
  schema {
    query: Query
    mutation: Mutation
    subscription: Subscription
  }
GRAPHQL

api = aws_appsync_graphql_api(:blog_api, {
  name: "BlogAPI",
  authentication_type: "AMAZON_COGNITO_USER_POOLS",
  schema: schema_definition,
  user_pool_config: {
    user_pool_id: cognito_pool.id,
    aws_region: "us-east-1",
    default_action: "ALLOW"
  }
})
```

## Logging and Monitoring

### CloudWatch Logging
Configure detailed logging for debugging and monitoring:

```ruby
api = aws_appsync_graphql_api(:monitored_api, {
  name: "MonitoredAPI",
  authentication_type: "AWS_IAM",
  log_config: {
    cloudwatch_logs_role_arn: logging_role.arn,
    field_log_level: "ALL",  # NONE, ERROR, or ALL
    exclude_verbose_content: false  # Include request/response details
  }
})
```

### X-Ray Tracing
Enable distributed tracing for performance analysis:

```ruby
api = aws_appsync_graphql_api(:traced_api, {
  name: "TracedAPI",
  authentication_type: "API_KEY",
  xray_enabled: true
})
```

## Security Best Practices

### 1. Query Depth Limiting
Prevent deeply nested queries that could cause performance issues:

```ruby
api = aws_appsync_graphql_api(:limited_api, {
  name: "LimitedAPI",
  authentication_type: "API_KEY",
  query_depth_limit: 10,  # Maximum nesting depth
  resolver_count_limit: 1000  # Maximum resolvers per request
})
```

### 2. Private APIs
Restrict API access to VPC endpoints:

```ruby
api = aws_appsync_graphql_api(:private_api, {
  name: "PrivateAPI",
  authentication_type: "AWS_IAM",
  visibility: "PRIVATE"  # Only accessible via VPC endpoint
})
```

### 3. Lambda Authorizers
Implement custom authorization logic:

```ruby
api = aws_appsync_graphql_api(:custom_auth_api, {
  name: "CustomAuthAPI",
  authentication_type: "AWS_LAMBDA",
  lambda_authorizer_config: {
    authorizer_uri: authorizer_lambda.arn,
    authorizer_result_ttl_in_seconds: 300,  # Cache authorization results
    identity_validation_expression: "^Bearer [-0-9a-zA-z\.]*$"  # Validate token format
  }
})
```

## Merged APIs

Merged APIs allow combining multiple source GraphQL APIs into a single endpoint:

```ruby
# Create source APIs
user_api = aws_appsync_graphql_api(:user_api, {
  name: "UserServiceAPI",
  authentication_type: "AWS_IAM",
  schema: user_schema
})

order_api = aws_appsync_graphql_api(:order_api, {
  name: "OrderServiceAPI", 
  authentication_type: "AWS_IAM",
  schema: order_schema
})

# Create merged API
merged_api = aws_appsync_graphql_api(:merged_api, {
  name: "UnifiedAPI",
  authentication_type: "API_KEY",
  api_type: "MERGED",
  merged_api_execution_role_arn: merge_role.arn
})
```

## Integration Patterns

### 1. Real-time Subscriptions
Enable real-time data updates:

```ruby
api = aws_appsync_graphql_api(:realtime_api, {
  name: "RealtimeAPI",
  authentication_type: "API_KEY",
  schema: <<-GRAPHQL
    type Subscription {
      onMessageCreated(channelId: ID!): Message
        @aws_subscribe(mutations: ["createMessage"])
      
      onUserStatusChanged(userId: ID!): UserStatus
        @aws_subscribe(mutations: ["updateUserStatus"])
    }
  GRAPHQL
})
```

### 2. Federation Support
Support Apollo Federation for microservices:

```ruby
api = aws_appsync_graphql_api(:federated_api, {
  name: "FederatedServiceAPI",
  authentication_type: "AWS_IAM",
  schema: <<-GRAPHQL
    extend type Query {
      user(id: ID!): User
    }
    
    type User @key(fields: "id") {
      id: ID!
      name: String!
      orders: [Order!]!
    }
  GRAPHQL
})
```

## Common Issues and Solutions

### Authentication Configuration Mismatch
The resource validates that authentication configurations match the selected authentication type:

```ruby
# This will fail validation
api = aws_appsync_graphql_api(:invalid_api, {
  name: "InvalidAPI",
  authentication_type: "AMAZON_COGNITO_USER_POOLS"
  # Error: user_pool_config is required for Cognito authentication
})

# Correct configuration
api = aws_appsync_graphql_api(:valid_api, {
  name: "ValidAPI",
  authentication_type: "AMAZON_COGNITO_USER_POOLS",
  user_pool_config: {
    user_pool_id: "us-east-1_aBcDeFgHi",
    aws_region: "us-east-1"
  }
})
```

### Schema Validation
Ensure GraphQL schemas are valid before deployment:

```ruby
# Validate schema programmatically
require 'graphql'

schema_ast = GraphQL.parse(schema_string)
# Additional validation logic
```

## Performance Optimization

### 1. Caching Strategy
Implement caching at multiple levels:

```ruby
# API-level caching configuration
api = aws_appsync_graphql_api(:cached_api, {
  name: "CachedAPI",
  authentication_type: "API_KEY"
})

# Configure caching on resolvers (separate resource)
# See aws_appsync_resolver documentation
```

### 2. Batching and DataLoader
Optimize N+1 queries through batching:

```ruby
# Configure batch resolvers in data sources
# See aws_appsync_datasource documentation
```

## Cost Considerations

1. **Request Pricing**: Charged per million requests
2. **Real-time Connection Minutes**: For subscriptions
3. **Data Transfer**: Standard AWS data transfer rates
4. **Caching**: Can reduce backend calls and costs

## Terraform State Considerations

The GraphQL schema is stored in Terraform state. For large schemas, consider:

1. Storing schemas in separate files
2. Using templatefile() function for schema management
3. Version controlling schema changes separately