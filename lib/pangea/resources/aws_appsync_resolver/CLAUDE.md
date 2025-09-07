# AWS AppSync Resolver - Developer Guide

## Overview

The `aws_appsync_resolver` resource connects GraphQL fields to data sources, implementing the business logic that fetches and manipulates data in AppSync APIs. Resolvers are the heart of GraphQL operations, translating GraphQL queries into data source operations.

## Resolver Architecture

### UNIT Resolvers
UNIT resolvers connect directly to a single data source and execute simple request-response operations:

```ruby
# Direct DynamoDB query
resolver = aws_appsync_resolver(:get_user, {
  api_id: api.id,
  type: "Query",
  field: "getUser",
  data_source: dynamodb_datasource.name,
  request_template: <<-VTL
    {
      "version": "2018-05-29",
      "operation": "GetItem",
      "key": {
        "id": $util.dynamodb.toDynamoDBJson($ctx.args.id)
      }
    }
  VTL,
  response_template: "$util.toJson($ctx.result)"
})
```

### PIPELINE Resolvers
PIPELINE resolvers orchestrate multiple functions in sequence, enabling complex data processing workflows:

```ruby
# Multi-step data aggregation
resolver = aws_appsync_resolver(:user_dashboard, {
  api_id: api.id,
  type: "Query", 
  field: "getUserDashboard",
  kind: "PIPELINE",
  pipeline_config: {
    functions: [
      get_user_function.function_id,
      get_user_posts_function.function_id,
      get_user_notifications_function.function_id,
      calculate_user_stats_function.function_id
    ]
  },
  request_template: <<-VTL
    ## Initialize stash for sharing data between functions
    $util.qr($ctx.stash.put("userId", $ctx.args.id))
    {
      "version": "2018-05-29"
    }
  VTL,
  response_template: <<-VTL
    ## Aggregate results from all functions
    {
      "user": $util.toJson($ctx.stash.user),
      "posts": $util.toJson($ctx.stash.posts),
      "notifications": $util.toJson($ctx.stash.notifications),
      "stats": $util.toJson($ctx.stash.stats)
    }
  VTL
})
```

## Runtime Environments

### VTL (Velocity Template Language)
Traditional mapping templates with full AppSync utility access:

```ruby
resolver = aws_appsync_resolver(:vtl_resolver, {
  api_id: api.id,
  type: "Mutation",
  field: "createPost",
  data_source: dynamodb_datasource.name,
  request_template: <<-VTL
    ## Advanced VTL with validation and transformation
    #set($input = $ctx.args.input)
    
    ## Validate required fields
    #if(!$input.title || $input.title == "")
      $util.error("Title is required", "ValidationError")
    #end
    
    ## Generate unique ID and timestamp
    #set($id = $util.autoId())
    #set($now = $util.time.nowISO8601())
    
    ## Prepare item for DynamoDB
    {
      "version": "2018-05-29",
      "operation": "PutItem",
      "key": {
        "id": $util.dynamodb.toDynamoDBJson($id),
        "authorId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub)
      },
      "attributeValues": {
        "title": $util.dynamodb.toDynamoDBJson($input.title),
        "content": $util.dynamodb.toDynamoDBJson($input.content),
        "createdAt": $util.dynamodb.toDynamoDBJson($now),
        "updatedAt": $util.dynamodb.toDynamoDBJson($now),
        "status": $util.dynamodb.toDynamoDBJson("PUBLISHED")
      },
      "condition": {
        "expression": "attribute_not_exists(id)"
      }
    }
  VTL,
  response_template: <<-VTL
    ## Handle conditional check failures
    #if($ctx.error && $ctx.error.type == "DynamoDB:ConditionalCheckFailedException")
      $util.error("Post with this ID already exists", "DuplicateError", $ctx.result)
    #elseif($ctx.error)
      $util.error($ctx.error.message, $ctx.error.type, $ctx.result)
    #else
      $util.toJson($ctx.result)
    #end
  VTL
})
```

### JavaScript Runtime (APPSYNC_JS)
Modern ES6+ JavaScript with enhanced developer experience:

```ruby
resolver = aws_appsync_resolver(:js_resolver, {
  api_id: api.id,
  type: "Query",
  field: "searchPosts",
  data_source: elasticsearch_datasource.name,
  runtime: {
    name: "APPSYNC_JS",
    runtime_version: "1.0.0"
  },
  code: <<-JS
    import { util } from '@aws-appsync/utils';
    
    export function request(ctx) {
      const { query, filters, pagination } = ctx.args;
      
      // Build Elasticsearch query
      const searchQuery = {
        query: {
          bool: {
            must: [
              {
                multi_match: {
                  query: query,
                  fields: ['title^2', 'content', 'tags'],
                  type: 'best_fields',
                  fuzziness: 'AUTO'
                }
              }
            ],
            filter: []
          }
        },
        sort: [
          { createdAt: { order: 'desc' } },
          '_score'
        ],
        from: (pagination.page - 1) * pagination.limit,
        size: pagination.limit
      };
      
      // Apply filters
      if (filters.category) {
        searchQuery.query.bool.filter.push({
          term: { 'category.keyword': filters.category }
        });
      }
      
      if (filters.dateRange) {
        searchQuery.query.bool.filter.push({
          range: {
            createdAt: {
              gte: filters.dateRange.from,
              lte: filters.dateRange.to
            }
          }
        });
      }
      
      return {
        operation: 'GET',
        path: '/posts/_search',
        params: {
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(searchQuery)
        }
      };
    }
    
    export function response(ctx) {
      if (ctx.error) {
        util.error(ctx.error.message, ctx.error.type);
      }
      
      const result = JSON.parse(ctx.result.body);
      
      return {
        items: result.hits.hits.map(hit => ({
          ...hit._source,
          score: hit._score
        })),
        total: result.hits.total.value,
        aggregations: result.aggregations
      };
    }
  JS
})
```

## Advanced Resolver Patterns

### Batch Resolution
Optimize N+1 queries with batch operations:

```ruby
resolver = aws_appsync_resolver(:batch_users, {
  api_id: api.id,
  type: "Post",
  field: "author",
  data_source: dynamodb_datasource.name,
  max_batch_size: 25,
  request_template: <<-VTL
    ## Batch get users for multiple posts
    {
      "version": "2018-05-29",
      "operation": "BatchGetItem",
      "tables": {
        "Users": {
          "keys": [
            #foreach($item in $ctx.source)
            {
              "id": $util.dynamodb.toDynamoDBJson($item.authorId)
            }#if($foreach.hasNext),#end
            #end
          ]
        }
      }
    }
  VTL,
  response_template: <<-VTL
    ## Map users back to posts
    #set($users = {})
    #foreach($user in $ctx.result.data.Users)
      $util.qr($users.put($user.id, $user))
    #end
    
    [
      #foreach($item in $ctx.source)
      $util.toJson($users.get($item.authorId))#if($foreach.hasNext),#end
      #end
    ]
  VTL
})
```

### Subscription Resolvers
Real-time data updates with conflict resolution:

```ruby
resolver = aws_appsync_resolver(:message_subscription, {
  api_id: api.id,
  type: "Subscription",
  field: "onMessageAdded",
  data_source: none_datasource.name,
  sync_config: {
    conflict_detection: "VERSION",
    conflict_handler: "OPTIMISTIC_CONCURRENCY"
  },
  request_template: <<-VTL
    ## Filter subscription by channel
    {
      "version": "2018-05-29",
      "payload": {
        "channelId": $util.toJson($ctx.args.channelId),
        "userId": $util.toJson($ctx.identity.sub)
      }
    }
  VTL,
  response_template: <<-VTL
    ## Return filtered message
    #if($ctx.result.channelId == $ctx.args.channelId)
      $util.toJson($ctx.result)
    #else
      null
    #end
  VTL
})
```

### Cached Resolvers
Improve performance with intelligent caching:

```ruby
resolver = aws_appsync_resolver(:popular_content, {
  api_id: api.id,
  type: "Query",
  field: "getPopularContent",
  data_source: dynamodb_datasource.name,
  caching_config: {
    caching_keys: [
      "$context.arguments.category",
      "$context.arguments.timeframe",
      "$context.identity.userType"
    ],
    ttl: 900  # 15 minutes
  },
  request_template: <<-VTL
    ## Generate cache-aware query
    #set($cacheKey = "${ctx.args.category}_${ctx.args.timeframe}_${ctx.identity.userType}")
    
    {
      "version": "2018-05-29",
      "operation": "Query",
      "index": "PopularContentIndex",
      "query": {
        "expression": "category = :category AND #timeframe = :timeframe",
        "expressionNames": {
          "#timeframe": "timeframe"
        },
        "expressionValues": {
          ":category": $util.dynamodb.toDynamoDBJson($ctx.args.category),
          ":timeframe": $util.dynamodb.toDynamoDBJson($ctx.args.timeframe)
        }
      },
      "limit": 20,
      "scanIndexForward": false
    }
  VTL
})
```

## Error Handling Strategies

### Graceful Error Recovery
```ruby
resolver = aws_appsync_resolver(:resilient_resolver, {
  api_id: api.id,
  type: "Query",
  field: "getUserWithFallback",
  data_source: dynamodb_datasource.name,
  response_template: <<-VTL
    ## Handle various error scenarios
    #if($ctx.error)
      #if($ctx.error.type == "DynamoDB:AmazonDynamoDBException")
        ## Database unavailable - return cached data or default
        {
          "id": $util.toJson($ctx.args.id),
          "name": "User temporarily unavailable",
          "error": {
            "type": "ServiceUnavailable",
            "message": "User data temporarily unavailable"
          }
        }
      #elseif($ctx.error.type == "ValidationException")
        $util.error("Invalid user ID format", "ValidationError")
      #else
        $util.error($ctx.error.message, $ctx.error.type)
      #end
    #elseif(!$ctx.result)
      ## User not found - return null or default user
      null
    #else
      $util.toJson($ctx.result)
    #end
  VTL
})
```

### Custom Conflict Resolution
```ruby
resolver = aws_appsync_resolver(:conflict_resolver, {
  api_id: api.id,
  type: "Mutation",
  field: "updateUserProfile",
  data_source: dynamodb_datasource.name,
  sync_config: {
    conflict_detection: "VERSION",
    conflict_handler: "LAMBDA",
    lambda_conflict_handler_config: {
      lambda_conflict_handler_arn: conflict_lambda.arn
    }
  }
})
```

## Testing and Debugging

### Request Tracing
Enable detailed tracing for resolver debugging:

```ruby
# Enable X-Ray tracing at the API level
api = aws_appsync_graphql_api(:traced_api, {
  name: "TracedAPI",
  authentication_type: "API_KEY",
  xray_enabled: true
})

# Resolvers automatically inherit tracing
resolver = aws_appsync_resolver(:traced_resolver, {
  api_id: api.id,
  type: "Query",
  field: "tracedQuery",
  data_source: datasource.name,
  request_template: <<-VTL
    ## Add custom trace segments
    $util.qr($ctx.stash.put("traceInfo", {
      "requestId": $ctx.requestId,
      "timestamp": $util.time.nowEpochMilliSeconds(),
      "userId": $ctx.identity.sub
    }))
    
    {
      "version": "2018-05-29",
      "operation": "GetItem",
      "key": {
        "id": $util.dynamodb.toDynamoDBJson($ctx.args.id)
      }
    }
  VTL
})
```

### Performance Optimization

1. **Minimize Template Complexity**: Keep VTL templates simple and focused
2. **Use Batch Operations**: Reduce round trips with batch resolvers
3. **Implement Caching**: Cache expensive operations appropriately
4. **Optimize Data Source Queries**: Use indexes and filters effectively
5. **Profile with Metrics**: Monitor resolver performance metrics

### Common Pitfalls

1. **Infinite Loops**: Be careful with recursive resolvers
2. **Memory Leaks**: Clean up stash data in pipeline resolvers
3. **Security Issues**: Validate inputs and implement proper authorization
4. **Performance Degradation**: Monitor resolver execution times
5. **Error Propagation**: Handle errors gracefully to maintain user experience

## Integration with Data Sources

Resolvers work differently with each data source type:

- **DynamoDB**: Use DynamoDB-specific operations and conditions
- **Lambda**: Pass context information and handle function responses
- **HTTP**: Transform requests/responses for REST API compatibility
- **RDS**: Execute SQL queries with parameterized statements
- **Elasticsearch**: Build complex search queries and aggregations
- **None**: Perform local data transformation and validation