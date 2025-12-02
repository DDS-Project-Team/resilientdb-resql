#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

# Launcher for the KV service with optional DuckDB flags.
# Uses the same topology as start_kv_service.sh but injects DuckDB flags
# when present.

set -euo pipefail

killall -9 kv_service >/dev/null 2>&1 || true

SERVER_PATH=./bazel-bin/service/kv/kv_service
SERVER_CONFIG=service/tools/config/server/server.config
WORK_PATH=$PWD
CERT_PATH=${WORK_PATH}/service/tools/data/cert/

# Always enable DuckDB with a default path per node.
DEFAULT_DUCKDB_PATH=${WORK_PATH}
EXTRA_FLAGS="--enable_duckdb"

start_node() {
  local node_id=$1
  local port=$2
  local key_file=$3
  local cert_file=$4

  local db_dir=${DEFAULT_DUCKDB_PATH}/${port}_db
  mkdir -p "${db_dir}"
  local db_path=${db_dir}/resdb.duckdb

  nohup $SERVER_PATH $SERVER_CONFIG $CERT_PATH/${key_file} $CERT_PATH/${cert_file} $EXTRA_FLAGS --duckdb_path=${db_path} > server${node_id}.log &
}

# No additional flag parsing; DuckDB is always enabled.
bazel build //service/kv:kv_service

start_node 0 10001 node1.key.pri cert_1.cert
start_node 1 10002 node2.key.pri cert_2.cert
start_node 2 10003 node3.key.pri cert_3.cert
start_node 3 10004 node4.key.pri cert_4.cert

# Optional client node (uses a distinct DB path as well)
start_node 4 10005 node5.key.pri cert_5.cert

echo "Started KV service with DuckDB enabled."
