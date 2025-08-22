# data-infra

Minimal infra repo. Phase 1 = MinIO on a private-IP VM.

## layout
- compose/minio/   : Docker Compose for MinIO
- env/             : env templates (no secrets)
- Makefile         : helper targets

## quickstart (later)
make sync
make vm_init_dirs
make deploy_minio
make minio_bucket
make minio_status
