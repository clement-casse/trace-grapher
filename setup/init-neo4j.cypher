CALL apoc.schema.assert(
    // Indices on Non-unique Resources
    {
        Resource: ['name'],
        Span: ['id'],
        TTL: ['ttl']
    },
    // Indices and Uniqueness contraints
    {
        Operation:['name'],
        Trace:['id'],
        Span:['uniqId']
    },
    // Delete before recreating schema
    true
)