#!/bin/bash
trace_ttl=${TRACE_TTL:-172800}
dependencies_ttl=${DEPENDENCIES_TTL:-0}
template_file=$(ls $(dirname $0)/*cql.tmpl | sort | tail -1)


if [[ "$MODE" == "" ]]; then
    usage "missing MODE parameter"
elif [[ "$MODE" == "prod" ]]; then
    if [[ "$DATACENTER" == "" ]]; then echo "missing DATACENTER parameter for prod mode"; fi
    datacenter=$DATACENTER
    replication_factor=${REPLICATION_FACTOR:-2}
    replication="{'class': 'NetworkTopologyStrategy', '$datacenter': '${replication_factor}' }"
elif [[ "$MODE" == "test" ]]; then
    datacenter=${DATACENTER:-'test'}
    replication_factor=${REPLICATION_FACTOR:-1}
    replication="{'class': 'SimpleStrategy', 'replication_factor': '${replication_factor}'}"
else
    usage "invalid MODE=$MODE, expecting 'prod' or 'test'"
fi

keyspace=${KEYSPACE:-"jaeger_v1_${datacenter}"}

if [[ $keyspace =~ [^a-zA-Z0-9_] ]]; then
    usage "invalid characters in KEYSPACE=$keyspace parameter, please use letters, digits or underscores"
fi

>&2 cat <<EOF
Using template file ${template_file} with parameters:
    mode = $MODE
    datacenter = $datacenter
    keyspace = $keyspace
    replication = ${replication}
    trace_ttl = ${trace_ttl}
    dependencies_ttl = ${dependencies_ttl}
EOF

# strip out comments, collapse multiple adjacent empty lines (cat -s), substitute variables
cat ${template_file} | sed \
    -e 's/--.*$//g'                                 \
    -e 's/^\s*$//g'                                 \
    -e "s/\${keyspace}/${keyspace}/g"               \
    -e "s/\${replication}/${replication}/g"         \
    -e "s/\${trace_ttl}/${trace_ttl}/g"             \
    -e "s/\${dependencies_ttl}/${dependencies_ttl}/g" \
| cat -s \
| /usr/bin/cqlsh $TARGET