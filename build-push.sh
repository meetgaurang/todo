#!/bin/bash
set -e

if [ -z "$DOCKERHUB_USERNAME" ]; then
  echo "Error: DOCKERHUB_USERNAME env var is not set."
  echo "Run: export DOCKERHUB_USERNAME=your_dockerhub_username"
  exit 1
fi

echo "Logging in to Docker Hub..."
docker login

echo "Setting up multi-platform builder..."
docker buildx create --name multiarch --use --bootstrap 2>/dev/null || docker buildx use multiarch

echo "Building and pushing images for linux/amd64 as $DOCKERHUB_USERNAME..."
docker buildx build --platform linux/amd64 \
  --push \
  -t "$DOCKERHUB_USERNAME/todo-backend:latest" \
  ./backend

docker buildx build --platform linux/amd64 \
  --push \
  -t "$DOCKERHUB_USERNAME/todo-frontend:latest" \
  ./frontend

echo ""
echo "Done. Images pushed:"
echo "  docker.io/$DOCKERHUB_USERNAME/todo-frontend:latest"
echo "  docker.io/$DOCKERHUB_USERNAME/todo-backend:latest"
