# dockerbackup

A simple shell script to back up Docker containers, images, and volumes.

## Usage

```bash
./dockerbackup.sh /path/to/backup/directory [--include_images] [--exclude_containers <c1,c2>] [--exclude_images <i1,i2>] [--exclude_volumes <v1,v2>]
```

- `/path/to/backup/directory`: The directory where the backup files will be stored. This is a required argument.
- `[--include_images]`: An optional argument to include Docker images in the backup.
- `[--exclude_containers <c1,c2>]`: An optional argument to exclude a comma-separated list of containers from the backup.
- `[--exclude_images <i1,i2>]`: An optional argument to exclude a comma-separated list of images from the backup.
- `[--exclude_volumes <v1,v2>]`: An optional argument to exclude a comma-separated list of volumes from the backup.

## What it backs up

- **Docker Containers**: Exports all containers (both running and stopped) as `.tar` files.
- **Docker Images**: If the `--include_images` flag is provided, it saves all Docker images as `.tar` files.
- **Docker Volumes**: Backs up all Docker volumes as `.tar.gz` files.

## Prerequisites

- Docker must be installed and running on the system where you run the script.
- The script uses the `busybox` image to back up volumes. If you don't have it, Docker will pull it automatically.

## Additional notes

- Ensure your save path is included in a cloud backup to ensure offsite backup of the files.
- Use crontab for automated backups. It will currently overwrite the last backup file, so it only retains the most recent backup. I have an incremental cloud backup system in place that handles changes over time for me.
