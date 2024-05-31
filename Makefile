###予めnodeとyarnのインストールが必要
include .env
default:
	@make init
up:
	vendor/laravel/sail/bin/sail up -d
build:
	vendor/laravel/sail/bin/sail build --no-cache --force-rm
laravel-install:
	vendor/laravel/sail/bin/sail exec app composer create-project --prefer-dist laravel/laravel .
create-project:
	@make build
	@make up
	@make laravel-install
	vendor/laravel/sail/bin/sail exec app php artisan key:generate
	vendor/laravel/sail/bin/sail exec app php artisan storage:link
	vendor/laravel/sail/bin/sail exec app chmod -R 777 storage bootstrap/cache
	@make npm-install
	@make fresh
install-recommend-packages:
	vendor/laravel/sail/bin/sail exec app composer require doctrine/dbal "^2"
	vendor/laravel/sail/bin/sail exec app composer require --dev ucan-lab/laravel-dacapo
	vendor/laravel/sail/bin/sail exec app composer require --dev barryvdh/laravel-ide-helper
	vendor/laravel/sail/bin/sail exec app composer require --dev beyondcode/laravel-dump-server
	vendor/laravel/sail/bin/sail exec app composer require --dev barryvdh/laravel-debugbar
	vendor/laravel/sail/bin/sail exec app composer require --dev roave/security-advisories:dev-master
	vendor/laravel/sail/bin/sail exec app php artisan vendor:publish --provider="BeyondCode\DumpServer\DumpServerServiceProvider"
	vendor/laravel/sail/bin/sail exec app php artisan vendor:publish --provider="Barryvdh\Debugbar\ServiceProvider"
init:
	docker-compose up -d app --build
	docker-compose exec app composer install
	-@vendor/laravel/sail/bin/sail exec app bash -c "if [ ! -e .env ];then cp .env.example .env && echo '.env created.'; else echo 'already created .env'; fi"
	vendor/laravel/sail/bin/sail down app --remove-orphans
	vendor/laravel/sail/bin/sail up -d --build
	vendor/laravel/sail/bin/sail exec app sleep 30
	vendor/laravel/sail/bin/sail exec app sudo chmod 777 -R /var/www/html
	vendor/laravel/sail/bin/sail exec app php artisan key:generate
	-vendor/laravel/sail/bin/sail exec app sudo chmod -R 777 storage
	-vendor/laravel/sail/bin/sail exec app sudo chmod -R 777 bootstrap/cache
#	mysqlを使用する場合はコメントを解除
#	@vendor/laravel/sail/bin/sail exec mysql bash -c 'until mysqladmin ping -h mysql --silent; do echo "mysql 起動待機中..."; sleep 2; done;'
#	@make db-authority-settings
#	vendor/laravel/sail/bin/sail exec app php artisan migrate
#	vendor/laravel/sail/bin/sail exec app php artisan db:seed # laravelのシーディングを利用する場合有効
	@vendor/laravel/sail/bin/sail exec app echo "setup all done."
init-direct:
	export NODE_OPTIONS="--max-old-space-size=1024"
	php ./composer.phar install
	-@chmod 777 -R ./
	php artisan key:generate
	-@chmod -R 777 storage bootstrap/cache
#	mysqlを使用する場合はコメントを解除
#	php artisan db:seed
#	php ./artisan migrate
	@echo "setup all done."
remake:
	@make destroy
	@make init
remake-direct:
	@make destroy-direct
	@make init-direct
stop:
	vendor/laravel/sail/bin/sail stop
down:
	vendor/laravel/sail/bin/sail down --remove-orphans
restart:
	@make down
	@make up
destroy:
	vendor/laravel/sail/bin/sail exec app unlink /var/www/html/public/storage
	vendor/laravel/sail/bin/sail exec app unlink /var/www/html/public/doc
	vendor/laravel/sail/bin/sail exec app rm -rf /var/www/html/storage/answer-pdf-test/* /var/www/html/storage/docstorage-local/* /var/www/html/storage/filestorage-local/*  /var/www/html/storage/request-csv-test/*
	vendor/laravel/sail/bin/sail down --rmi all --volumes --remove-orphans
destroy-direct:
	unlink ./public/storage
	unlink ./public/doc
	rm -rf ./storage/answer-pdf-test/* /var/www/html/storage/docstorage-local/* /var/www/html/storage/filestorage-local/*  /var/www/html/storage/request-csv-test/*
destroy-volumes:
	vendor/laravel/sail/bin/sail down --volumes --remove-orphans
ps:
	vendor/laravel/sail/bin/sail ps
logs:
	vendor/laravel/sail/bin/sail logs
logs-watch:
	vendor/laravel/sail/bin/sail logs --follow
log-app:
	vendor/laravel/sail/bin/sail logs app
log-app-watch:
	vendor/laravel/sail/bin/sail logs --follow app
log-db:
	vendor/laravel/sail/bin/sail logs mysql
log-db-watch:
	vendor/laravel/sail/bin/sail logs --follow mysql
app:
	vendor/laravel/sail/bin/sail exec app bash
upgrade:
#	mysqlを使用する場合はコメントを解除
#	vendor/laravel/sail/bin/sail stop
#	vendor/laravel/sail/bin/sail up -d app mysql
#	@vendor/laravel/sail/bin/sail exec mysql bash -c 'until mysqladmin ping -h mysql --silent; do echo "mysql 起動待機中..."; sleep 2; done;'
#	@vendor/laravel/sail/bin/sail exec mysql bash -c "if [ ! -e /dbBackup/db_before_migrate.sql ];then mysqldump -u root -p$(DB_PASSWORD) --hex-blob $(DB_DATABASE) > /dbBackup/db_before_migrate.sql && echo 'db backed up.'; else echo 'already db backed up.'; fi"
	vendor/laravel/sail/bin/sail down --remove-orphans --volumes
	docker compose up -d --build
#	@vendor/laravel/sail/bin/sail exec mysql bash -c 'until mysqladmin ping -h mysql --silent; do echo "mysql 起動待機中..."; sleep 2; done;'
#	vendor/laravel/sail/bin/sail exec mysql bash -c "mysql -u root -p$(DB_PASSWORD) $(DB_DATABASE) < /dbBackup/db_before_migrate.sql"
	vendor/laravel/sail/bin/sail exec app composer install
#	mysqlを使用する場合はコメントを解除
#	@make db-authority-settings
#	vendor/laravel/sail/bin/sail exec app php artisan migrate
#	vendor/laravel/sail/bin/sail exec app php artisan db:seed # laravelのシーディングを利用する場合有効
	@vendor/laravel/sail/bin/sail exec app echo "migrate all done."
upgrade-direct:
	export NODE_OPTIONS="--max-old-space-size=1024"
	php ./composer.phar install
#	mysqlを使用する場合はコメントを解除
#	php artisan migrate
#	php artisan db:seed
	@echo "migrate all done."
db-authority-settings:
	vendor/laravel/sail/bin/sail exec mysql bash -c "echo \"create user 'root'@'127.*' identified by '$(DB_PASSWORD)';\" | mysql -u root -p$(DB_PASSWORD) $(DB_DATABASE)"
	vendor/laravel/sail/bin/sail exec mysql bash -c "echo \"grant all on $(DB_DATABASE).* to 'root'@'127.*' with grant option;\" | mysql -u root -p$(DB_PASSWORD) $(DB_DATABASE)"
	vendor/laravel/sail/bin/sail exec mysql bash -c "echo \"create user 'root'@'172.*' identified by '$(DB_PASSWORD)';\" | mysql -u root -p$(DB_PASSWORD) $(DB_DATABASE)"
	vendor/laravel/sail/bin/sail exec mysql bash -c "echo \"grant all on $(DB_DATABASE).* to 'root'@'172.*' with grant option;\" | mysql -u root -p$(DB_PASSWORD) $(DB_DATABASE)"
	vendor/laravel/sail/bin/sail exec mysql bash -c "echo \"create user 'root'@'192.*' identified by '$(DB_PASSWORD)';\" | mysql -u root -p$(DB_PASSWORD) $(DB_DATABASE)"
	vendor/laravel/sail/bin/sail exec mysql bash -c "echo \"grant all on $(DB_DATABASE).* to 'root'@'192.*' with grant option;\" | mysql -u root -p$(DB_PASSWORD) $(DB_DATABASE)"
	vendor/laravel/sail/bin/sail exec mysql bash -c "echo \"create user 'root'@'_gateway' identified by '$(DB_PASSWORD)';\" | mysql -u root -p$(DB_PASSWORD) $(DB_DATABASE)"
	vendor/laravel/sail/bin/sail exec mysql bash -c "echo \"grant all on $(DB_DATABASE).* to 'root'@'_gateway' with grant option;\" | mysql -u root -p$(DB_PASSWORD) $(DB_DATABASE)"
	vendor/laravel/sail/bin/sail exec mysql bash -c "echo \"create user '$(DB_USERNAME)'@'127.*' identified by '$(DB_PASSWORD)';\" | mysql -u root -p$(DB_PASSWORD) $(DB_DATABASE)"
	vendor/laravel/sail/bin/sail exec mysql bash -c "echo \"grant all on $(DB_DATABASE).* to '$(DB_USERNAME)'@'127.*' with grant option;\" | mysql -u root -p$(DB_PASSWORD) $(DB_DATABASE)"
	vendor/laravel/sail/bin/sail exec mysql bash -c "echo \"create user '$(DB_USERNAME)'@'172.*' identified by '$(DB_PASSWORD)';\" | mysql -u root -p$(DB_PASSWORD) $(DB_DATABASE)"
	vendor/laravel/sail/bin/sail exec mysql bash -c "echo \"grant all on $(DB_DATABASE).* to '$(DB_USERNAME)'@'172.*' with grant option;\" | mysql -u root -p$(DB_PASSWORD) $(DB_DATABASE)"
	vendor/laravel/sail/bin/sail exec mysql bash -c "echo \"create user '$(DB_USERNAME)'@'192.*' identified by '$(DB_PASSWORD)';\" | mysql -u root -p$(DB_PASSWORD) $(DB_DATABASE)"
	vendor/laravel/sail/bin/sail exec mysql bash -c "echo \"grant all on $(DB_DATABASE).* to '$(DB_USERNAME)'@'192.*' with grant option;\" | mysql -u root -p$(DB_PASSWORD) $(DB_DATABASE)"
	vendor/laravel/sail/bin/sail exec mysql bash -c "echo \"create user '$(DB_USERNAME)'@'_gateway' identified by '$(DB_PASSWORD)';\" | mysql -u root -p$(DB_PASSWORD) $(DB_DATABASE)"
	vendor/laravel/sail/bin/sail exec mysql bash -c "echo \"grant all on $(DB_DATABASE).* to '$(DB_USERNAME)'@'_gateway' with grant option;\" | mysql -u root -p$(DB_PASSWORD) $(DB_DATABASE)"
fresh:
	vendor/laravel/sail/bin/sail exec app php artisan migrate:fresh --seed
seed:
	vendor/laravel/sail/bin/sail exec app php artisan db:seed
dacapo:
	vendor/laravel/sail/bin/sail exec app php artisan dacapo
rollback-test:
	vendor/laravel/sail/bin/sail exec app php artisan migrate:fresh
	vendor/laravel/sail/bin/sail exec app php artisan migrate:refresh
tinker:
	vendor/laravel/sail/bin/sail exec app php artisan tinker
test:
	vendor/laravel/sail/bin/sail exec app php artisan test
optimize:
	vendor/laravel/sail/bin/sail exec app php artisan optimize
optimize-clear:
	vendor/laravel/sail/bin/sail exec app php artisan optimize:clear
cache:
	vendor/laravel/sail/bin/sail exec app composer dump-autoload -o
	@make optimize
	vendor/laravel/sail/bin/sail exec app php artisan event:cache
	vendor/laravel/sail/bin/sail exec app php artisan view:cache
cache-clear:
	vendor/laravel/sail/bin/sail exec app composer clear-cache
	@make optimize-clear
	vendor/laravel/sail/bin/sail exec app php artisan event:clear
npm:
	@make npm-install
npm-install:
	vendor/laravel/sail/bin/sail exec app pnpm install
dev:
	vendor/laravel/sail/bin/sail start
	@make npm-dev
npm-dev:
	vendor/laravel/sail/bin/sail exec app pnpm run dev
npm-build:
	vendor/laravel/sail/bin/sail exec app pnpm run build
npm-prod:
	@make npm-build
db:
	vendor/laravel/sail/bin/sail exec mysql bash
sql:
	vendor/laravel/sail/bin/sail exec app bash -c 'mysql -u $(DB_USERNAME) -h db -p$(DB_PASSWORD) $(DB_DATABASE)'
redis:
	vendor/laravel/sail/bin/sail exec redis redis-cli
ide-helper:
	vendor/laravel/sail/bin/sail exec app php artisan clear-compiled
	vendor/laravel/sail/bin/sail exec app php artisan ide-helper:generate
	vendor/laravel/sail/bin/sail exec app php artisan ide-helper:meta
	vendor/laravel/sail/bin/sail exec app php artisan ide-helper:models --nowrite
db-backup:
	vendor/laravel/sail/bin/sail stop
	vendor/laravel/sail/bin/sail up -d app mysql
	vendor/laravel/sail/bin/sail exec app bash -c "sleep 20"
	vendor/laravel/sail/bin/sail exec mysql bash -c "mysqldump -u root -p$(DB_PASSWORD) --hex-blob $(DB_DATABASE) > /dbBackup/db_backup_`date '+%Y%m%d%H%M%S'`.sql"
	vendor/laravel/sail/bin/sail up -d
doc-update:
	vendor/laravel/sail/bin/sail up -d app mysql
	vendor/laravel/sail/bin/sail exec app bash -c "rm -f /var/www/html/.scribe/endpoints.cache/*"
	vendor/laravel/sail/bin/sail exec app bash -c "php artisan scribe:generate"
