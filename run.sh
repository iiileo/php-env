#!/usr/bin/env bash
set -e

container_mode=${CONTAINER_MODE:-php-fpm}
project_dir=${PROJECT_DIR}
echo "Container mode: $container_mode"

# 非 php-fpm 启动需要 project_dir 设置目录
if [ "$container_mode" != "php-fpm" ] && [ -z "$project_dir" ]; then
    echo "Project Dir is empty"
    exit 1
fi

if [ "$1" != "" ]; then
  exec "$@"
elif [ ${container_mode} = "php-fpm" ]; then
  exec php-fpm
elif [ ${container_mode} = "octane" ]; then
  exec php ${project_dir}/artisan artisan octane:start --server=swoole --host=0.0.0.0 --port=9000 --workers=auto --task-workers=auto --max-requests=500
elif [ ${container_mode} = "horizon" ]; then
  exec php ${project_dir}/artisan horizon
elif [ ${container_mode} = "scheduler" ]; then
  echo "*/1 * * * * php ${project_dir}/artisan schedule:run --verbose --no-interaction" > /app/supercronic/laravel
  exec supercronic /etc/supercronic/laravel
else
  echo "Container mode mismatched."
  exit 1
fi