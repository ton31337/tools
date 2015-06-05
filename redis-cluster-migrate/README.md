### Usage
`redis-cli --scan | xargs -I {} ruby migrate.rb {} | bash`

Notice, that `COPY` and `REPLACE` flags are only available since Redis 3.0
