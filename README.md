# Todo App — Dockerised Full Stack App on AWS with Terraform

A full stack todo application built to showcase how to containerise and deploy a multi-service app to AWS EC2 using Terraform and Docker Hub.

## Stack

| Layer | Technology |
|---|---|
| Frontend | React (Vite), served by Nginx |
| Backend | Node.js, Express |
| Database | SQLite (persisted via Docker volume) |
| Containerisation | Docker, Docker Compose |
| Image Registry | Docker Hub |
| Infrastructure | AWS EC2, provisioned with Terraform |

## Architecture

```
Browser → EC2 :8080 → Nginx (frontend container)
                           ↓ /api/*
                       Express (backend container)
                           ↓
                       SQLite (Docker volume)
```

Nginx serves the React app and proxies all `/api/*` requests to the backend container. The two containers communicate over Docker's internal network — only port 8080 is exposed publicly.

## Project Structure

```
.
├── backend/              # Express API + SQLite
├── frontend/             # React app + Nginx config
├── infra/                # Terraform configs
│   ├── main.tf           # EC2 instance, security group, deploy provisioner
│   ├── variables.tf      # Input variables
│   ├── outputs.tf        # App URL and SSH command
│   ├── user_data.sh      # Bootstraps Docker + Compose on first boot
│   └── docker-compose.prod.tpl  # Production compose template (pull-only)
├── build-push.sh         # Builds images for linux/amd64 and pushes to Docker Hub
└── docker-compose.yml    # Local development compose file
```

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Terraform](https://developer.hashicorp.com/terraform/install) (`brew install hashicorp/tap/terraform`)
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials (`aws configure`)
- A Docker Hub account
- An AWS key pair (`.pem` file)

## Deployment

### 1. Configure AWS credentials

```bash
aws configure
```

### 2. Build and push images to Docker Hub

```bash
export DOCKERHUB_USERNAME=your_dockerhub_username
chmod +x build-push.sh
./build-push.sh
```

This builds the frontend and backend images for `linux/amd64` (required for EC2) and pushes them to Docker Hub.

### 3. Provision infrastructure and deploy

```bash
cd infra
terraform init
terraform apply \
  -var="private_key_path=~/path/to/keypair.pem" \
  -var="dockerhub_username=your_dockerhub_username"
```

Terraform will:
1. Create a security group (ports 22 and 8080)
2. Launch an Amazon Linux 2023 EC2 instance (`t2.micro`)
3. Bootstrap Docker and Docker Compose via `user_data.sh`
4. Copy the production compose file to the instance
5. Pull images from Docker Hub and start the containers

After `apply` completes, the app URL is printed:
```
app_url = "http://ec2-xx-xx-xx-xx.compute-1.amazonaws.com:8080"
```

### 4. Tear down

```bash
terraform destroy \
  -var="private_key_path=~/path/to/keypair.pem" \
  -var="dockerhub_username=your_dockerhub_username"
```

## Re-deploying After Code Changes

```bash
# 1. Push updated images
./build-push.sh

# 2. SSH into the instance and pull + restart
ssh -i ~/path/to/keypair.pem ec2-user@<public-dns>
cd ~/todo
sudo docker compose pull
sudo docker compose up -d
```

## Local Development

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) running

### Run the app

```bash
docker compose up --build
```

This builds both images locally and starts the containers. The app is available at `http://localhost:8080`.

### What runs locally

| Container | Role | Port |
|---|---|---|
| frontend | Nginx serving the React build, proxies `/api/*` | 8080 (host) |
| backend | Express API with SQLite | internal only |

SQLite data is stored in a Docker volume (`sqlite-data`) so it persists across restarts.

### Stop the app

```bash
docker compose down
```

To also delete the database volume:
```bash
docker compose down -v
```
