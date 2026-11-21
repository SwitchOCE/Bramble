#!/bin/bash
# run SurrealQL from stdin against store on port $1, print JSON
curl -s -u root:root -H 'surreal-ns: bramble' -H 'surreal-db: league' -H 'Accept: application/json' -X POST http://127.0.0.1:${1:-18603}/sql --data-binary @-
