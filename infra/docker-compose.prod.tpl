services:
  frontend:
    image: ${dockerhub_username}/todo-frontend:latest
    ports:
      - "8080:80"
    depends_on:
      - backend

  backend:
    image: ${dockerhub_username}/todo-backend:latest
    volumes:
      - sqlite-data:/data
    expose:
      - "3001"

volumes:
  sqlite-data:
