# ---- data-infra / Makefile (VM-local, MinIO only) ----
# Model: pull -> up. CI later will just: make deploy
# Run these on the VM from the repo root (/srv/data-infra).

BRANCH   ?= main
COMPOSE  := compose/minio/docker-compose.yml
ENVFILE  := compose/minio/.env.prod
MC_IMAGE := minio/mc:latest

## update working tree to the desired branch
pull:
	git fetch origin $(BRANCH)
	git checkout $(BRANCH)
	git pull --ff-only origin $(BRANCH)

## first-time VM prep for MinIO data dirs (idempotent)
bootstrap:
	sudo mkdir -p /opt/data/minio/{data,config}
	sudo chown -R $$(whoami):$$(whoami) /opt/data/minio

## start / update MinIO
up:
	docker compose -f $(COMPOSE) --env-file $(ENVFILE) up -d
	docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

## stop MinIO
down:
	docker compose -f $(COMPOSE) --env-file $(ENVFILE) down

## create the bucket named in .env.prod (safe to re-run)
bucket:
	docker run --rm --network host \
	  -e MC_HOST_local=$$(printf "http://%s:%s@%s:9000" \
	    "$$(grep ^MINIO_ROOT_USER $(ENVFILE) | cut -d= -f2)" \
	    "$$(grep ^MINIO_ROOT_PASSWORD $(ENVFILE) | cut -d= -f2)" \
	    "$$(grep ^MINIO_BIND_IP $(ENVFILE) | cut -d= -f2)") \
	  $(MC_IMAGE) mb -p local/$$(grep ^S3_BUCKET $(ENVFILE) | cut -d= -f2) || true

## list buckets (quick sanity check)
status:
	docker run --rm --network host \
	  -e MC_HOST_local=$$(printf "http://%s:%s@%s:9000" \
	    "$$(grep ^MINIO_ROOT_USER $(ENVFILE) | cut -d= -f2)" \
	    "$$(grep ^MINIO_ROOT_PASSWORD $(ENVFILE) | cut -d= -f2)" \
	    "$$(grep ^MINIO_BIND_IP $(ENVFILE) | cut -d= -f2)") \
	  $(MC_IMAGE) ls local/ || true

## tail recent logs for the minio service
logs:
	docker compose -f $(COMPOSE) --env-file $(ENVFILE) logs --tail=200 minio || true

## one-shot deploy used by humans and CI later
deploy: pull up
