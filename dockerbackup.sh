#! /bin/bash
# A simple script to back up Docker containers, images, and volumes
# Usage: ./dockerbackup.sh /path/to/backup/directory
BACKUP_DIR=$1
DO_IMAGES=$2

if [ -z "$BACKUP_DIR" ]; then
  echo "Usage: $0 /path/to/backup/directory [--include_images]"
  exit 1
fi
mkdir -p "$BACKUP_DIR"

# Backup Docker containers
CONTAINERS=$(docker ps -a -q)
for CONTAINER in $CONTAINERS; do
    CONTAINER_NAME=$(docker inspect --format='{{.Name}}' "$CONTAINER")
    CONTAINER_NAME=${CONTAINER_NAME#/}
    docker export "$CONTAINER" -o "$BACKUP_DIR/${CONTAINER_NAME}_container.tar"
    echo "Backed up container: $CONTAINER_NAME"
done
# Backup Docker 
if [ "$DO_IMAGES" == "--include_images" ]; then
    IMAGES=$(docker images -q | sort | uniq)
    for IMAGE in $IMAGES; do
        IMAGE_NAME=$(docker inspect --format='{{.RepoTags}}' "$IMAGE") |
        IMAGE_NAME=${IMAGE_NAME//[:\/]/_}
        IMAGE_NAME=${IMAGE_NAME//[\[\]]/}
        docker save "$IMAGE" -o "$BACKUP_DIR/${IMAGE_NAME}_image.tar"
        echo "Backed up image: $IMAGE_NAME"
    done
fi
# Backup Docker volumes
VOLUMES=$(docker volume ls -q)
for VOLUME in $VOLUMES; do
    docker run --rm -v "$VOLUME":/volume -v "$BACKUP_DIR":/backup busybox \
    tar czf /backup/"${VOLUME}_volume.tar.gz" -C /volume .
    echo "Backed up volume: $VOLUME"
done
echo "Docker backup completed. Backup files are located in $BACKUP_DIR"