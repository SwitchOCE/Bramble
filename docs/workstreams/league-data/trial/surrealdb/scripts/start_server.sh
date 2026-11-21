#!/bin/bash
# usage: start_server.sh <store-name> <port>   (writes pid to run/<store>.pid)
D=/data/dbtest/surrealdb
export SURREAL_RUNTIME_WORKER_THREADS=2 SURREAL_TEMPORARY_DIRECTORY=$D/tmp
mkdir -p $D/tmp $D/run
taskset -c 4,5 $D/bin/surreal start --log warn --user root --pass root --bind 127.0.0.1:$2 "surrealkv://$D/db/$1" >> $D/logs/server-$1.log 2>&1 &
echo $! > $D/run/$1.pid
