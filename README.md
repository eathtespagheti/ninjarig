# ninjarig docker image

Ninjarig image enabled to only CPU mine, minimum donation level it's set to 0

## Configuration

Drop your configuration file with a volume in `/ninjarig/config.json`

## docker compose

docker compose example

```yaml
ninjarig:
    image: eathtespagheti/ninjarig
    restart: always
    ports: 
      - 8080:80
    volumes: 
      - ./ninjarig/config.json:/ninjarig/config.json
```
