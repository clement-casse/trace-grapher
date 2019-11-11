MERGE (r:Resource{ name: event.process.serviceName })
    ON CREATE SET r += { created: timestamp() }
    ON MATCH SET r += { lastSeen: timestamp() }

MERGE (t:Trace{ id: event.traceId })
    ON CREATE SET t += { created: timestamp() }
    ON MATCH SET t += { lastSeen: timestamp() }
WITH event, r, t
CALL apoc.date.expireIn(t, 60, "m")

MERGE (s:Span{ id: event.spanId, uniqId: (event.traceId + event.spanId) })
    ON CREATE SET s += { duration: event.duration, startTime: datetime(event.startTime) }
    ON MATCH SET s:Span:Warning
WITH event, r, s, t
CALL apoc.date.expireIn(s, 60, 'm')

MERGE (o:Operation{ name: event.operationName })
    ON CREATE SET o += { created: timestamp() }
    ON MATCH SET o += { lastSeen: timestamp() }

MERGE (s)-[:FROM_TRACE]->(t)
MERGE (s)-[:MEASURE]->(o)
MERGE (s)-[:EXECUTES_ON]->(r)

WITH event, r, s, t
UNWIND event.process.tags AS processTag
WITH event, r, s, t, processTag
SET r += apoc.map.fromValues([processTag.key, processTag.vStr])

WITH event, r, s, t
UNWIND event.tags AS tag
WITH event, s, t, tag
SET s += apoc.map.fromValues([tag.key, tag.vStr])
