#!/usr/bin/env bash
exec 3<>/dev/tcp/HOST/6379

if [ $? -eq 0 ]; then
  echo -e "PING\r\n" >&3
  response=$(head -n 1 <&3)
  echo "Response: $response"
else
  echo "Connection failed"
fi

exec 3>&-
exec 3<&-
