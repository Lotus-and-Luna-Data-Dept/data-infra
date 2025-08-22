VM=hetzner-data-vm
REMOTE_DIR=~/data-infra
RSYNC=rsync -av --delete --exclude '.git'

sync:
	$(RSYNC) ./ $(VM):$(REMOTE_DIR)/

vm_init_dirs:
	ssh $(VM) 'sudo mkdir -p /opt/data/minio/{data,config} && sudo chown -R $$USER:$$USER /opt/data/minio'

deploy_minio:
	ssh $(VM) 'cd $(REMOTE_DIR)/compose/minio && docker compose --env-file .env.prod up -d'
	ssh $(VM) 'docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'

minio_bucket:
	ssh $(VM) 'cd $(REMOTE_DIR)/compose/minio && \
	  docker run --rm --network host \
	  -e MC_HOST_local=$$(printf "http://%s:%s@%s:9000" "$$(grep ^MINIO_ROOT_USER .env.prod|cut -d= -f2)" "$$(grep ^MINIO_ROOT_PASSWORD .env.prod|cut -d= -f2)" "$$(grep ^MINIO_BIND_IP .env.prod|cut -d= -f2)") \
	  quay.io/minio/mc:RELEASE.2025-02-18T17-00-00Z mb -p local/$$(grep ^S3_BUCKET .env.prod|cut -d= -f2) || true'

minio_status:
	ssh $(VM) 'cd $(REMOTE_DIR)/compose/minio && \
	  docker run --rm --network host \
	  -e MC_HOST_local=$$(printf "http://%s:%s@%s:9000" "$$(grep ^MINIO_ROOT_USER .env.prod|cut -d= -f2)" "$$(grep ^MINIO_ROOT_PASSWORD .env.prod|cut -d= -f2)" "$$(grep ^MINIO_BIND_IP .env.prod|cut -d= -f2)") \
	  quay.io/minio/mc:RELEASE.2025-02-18T17-00-00Z ls local/'

vm_open_private_ports:
	ssh $(VM) 'sudo ufw allow from 10.0.0.0/16 to any port 9000 proto tcp; sudo ufw allow from 10.0.0.0/16 to any port 9001 proto tcp; sudo ufw status'
