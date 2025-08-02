#!/usr/bin/bash

wget https://github.com/wal-g/wal-g/releases/download/v3.0.0/wal-g-pg-ubuntu-20.04-amd64.tar.gz

tar xzvf wal-g-pg-ubuntu-20.04-amd64.tar.gz

mv wal-g-pg-ubuntu-20.04-amd64 /usr/local/bin/wal-g


{
"WALE_S3_PREFIX": "s3://postgresql",
"AWS_ACCESS_KEY_ID": "mykey",
"AWS_ENDPOINT": "http://192.168.12.192:9000",
"AWS_S3_FORCE_PATH_STYLE": "true",
"AWS_SECRET_ACCESS_KEY": "password"
}


archive_command = '/usr/local/bin/wal-g --config /etc/walg.json wal-push %p'

