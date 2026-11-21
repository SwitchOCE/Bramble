#!/bin/bash
D=/data/dbtest/surrealdb; P=$(cat $D/run/$1.pid); kill -TERM $P; while kill -0 $P 2>/dev/null; do sleep 0.2; done; rm $D/run/$1.pid
