
install_deb_package(){

wget -qq https://dl.min.io/server/minio/release/linux-amd64/archive/minio_20230831153116.0.0_amd64.deb -O minio.deb
dpkg -i minio.deb
curl https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc && chmod +x /usr/local/bin/mc

}

install_systemd_service(){

echo '
[Unit]
Description=MinIO
Documentation=https://min.io/docs/minio/linux/index.html
Wants=network-online.target
After=network-online.target
AssertFileIsExecutable=/usr/local/bin/minio

[Service]
WorkingDirectory=/usr/local

User=minio
Group=minio
ProtectProc=invisible

EnvironmentFile=-/etc/default/minio
ExecStart=/usr/local/bin/minio server $MINIO_OPTS $MINIO_VOLUMES

Restart=always
LimitNOFILE=65536
TasksMax=infinity

TimeoutStopSec=infinity
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
' > /etc/systemd/system/minio.service

}

create_env_file(){

echo '
MINIO_ROOT_USER=Saliou
MINIO_ROOT_PASSWORD=password
MINIO_VOLUMES="/srv/minio"
MINIO_ACCESS_KEY=mykey
MINIO_SECRET_KEY=mypassword

# to change the url
#MINIO_SERVER_URL="http://minio.example.net:9000"

' >/etc/default/minio

}

create_user_dir(){

mkdir -p /srv/minio
groupadd -r minio
useradd -M -r -g minio minio
chown minio:minio /srv/minio/

}

start_systemd(){

systemctl start minio
systemctl enable minio

}

add_clickhouse_key(){

mc config host add myminio http://192.168.121.174:9000 Saliou password --api s3v4 

cat <<'EOF' > clickhouse.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::clickhouse"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::clickhouse/*"]
    }
  ]
}
EOF

mc admin policy create myminio ch_policy clickhouse.json
mc admin user add myminio clickhouse clickhousepassword
mc admin policy attach myminio ch_policy --user clickhouse
mc admin group add myminio ch_grp clickhouse
mc mb myminio/clickhouse
}

# Let's Go !! #################################################

install_deb_package
install_systemd_service
create_env_file
create_user_dir
start_systemd
add_clickhouse_key
