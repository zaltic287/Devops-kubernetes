#!/bin/bash

psql --username "$POSTGRES_USER" -d "$POSTGRES_DB" pulsar_manager -f /init.sql
