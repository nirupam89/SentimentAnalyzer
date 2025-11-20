# Docker Usage Guide

## Overview

This Dockerfile uses a **multi-stage build** process:
1. **Build Stage**: Compiles and packages the Spring Boot application into a JAR file
2. **Runtime Stage**: Creates a lightweight image with just the JRE and the built JAR file

The Docker image runs with the **`prod` profile** by default.

---

## Prerequisites

- Docker installed on your system
- PostgreSQL database (for production) or environment variables set up
- All required environment variables configured

---

## Basic Usage

### 1. Build the Docker Image

From the project root directory (where the Dockerfile is located):

```bash
docker build -t sentiment-analysis-service .
```

**Explanation**:
- `-t sentiment-analysis-service`: Tags the image with a name
- `.`: Build context (current directory)

**Build Process**:
- Stage 1: Downloads dependencies, compiles code, builds JAR file
- Stage 2: Creates final runtime image (much smaller)

### 2. Run the Container (Basic)

```bash
docker run -p 8080:8080 sentiment-analysis-service
```

**Explanation**:
- `-p 8080:8080`: Maps container port 8080 to host port 8080
- The app will be available at `http://localhost:8080`

---

## Running with Environment Variables

The production profile requires environment variables. Pass them using `-e` flag:

### Example: With Database Connection

```bash
docker run -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e DB_URL=jdbc:postgresql://your-db-host:5432/sentiment_db \
  -e DB_USER=your_username \
  -e DB_PASS=your_password \
  -e OLLAMA_BASE_URL=http://your-ollama-host:11434 \
  sentiment-analysis-service
```

### Using Environment File (.env)

Create a `.env` file in your project root:

```bash
# .env
SPRING_PROFILES_ACTIVE=prod
DB_URL=jdbc:postgresql://localhost:5432/sentiment_db
DB_USER=admin
DB_PASS=your_password
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama3
```

Then run with:

```bash
docker run -p 8080:8080 --env-file .env sentiment-analysis-service
```

**⚠️ Security Note**: Never commit `.env` files to Git! It's already in `.gitignore`.

### Using Render's PORT Variable

If deploying to Render, the PORT environment variable is automatically set. Docker will use it:

```bash
docker run -p ${PORT:-8080}:${PORT:-8080} \
  -e PORT=${PORT:-8080} \
  sentiment-analysis-service
```

---

## Advanced Usage

### Run in Background (Detached Mode)

```bash
docker run -d -p 8080:8080 \
  --name sentiment-api \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e DB_URL=... \
  sentiment-analysis-service
```

**Flags**:
- `-d`: Runs in detached mode (background)
- `--name sentiment-api`: Names the container for easy reference

### View Logs

```bash
docker logs sentiment-api
```

Or follow logs in real-time:

```bash
docker logs -f sentiment-api
```

### Stop and Remove Container

```bash
docker stop sentiment-api
docker rm sentiment-api
```

### Execute Commands Inside Container

```bash
docker exec -it sentiment-api sh
```

### Check Container Status

```bash
docker ps
```

To see all containers (including stopped):

```bash
docker ps -a
```

---

## Using Docker Compose (Recommended for Local Development)

Create a `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - DB_URL=jdbc:postgresql://db:5432/sentiment_db
      - DB_USER=admin
      - DB_PASS=password
      - OLLAMA_BASE_URL=http://ollama:11434
    depends_on:
      - db
      - ollama
    networks:
      - app-network

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=sentiment_db
      - POSTGRES_USER=admin
      - POSTGRES_PASSWORD=password
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - app-network

  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama-data:/root/.ollama
    networks:
      - app-network

volumes:
  postgres-data:
  ollama-data:

networks:
  app-network:
    driver: bridge
```

Then run:

```bash
docker-compose up --build
```

---

## Deployment to Render

### Option 1: Using Dockerfile (Automatic)

Render can automatically detect and use your Dockerfile:

1. Connect your GitHub repository to Render
2. Create a new **Web Service**
3. Render will:
   - Detect the Dockerfile
   - Build the image automatically
   - Run the container

### Option 2: Manual Build and Push to Registry

Build and tag for a registry:

```bash
# Tag for Docker Hub
docker build -t yourusername/sentiment-analysis-service:latest .

# Push to Docker Hub
docker push yourusername/sentiment-analysis-service:latest
```

### Environment Variables in Render

Set these in Render Dashboard → Environment:
- `SPRING_PROFILES_ACTIVE=prod`
- `DB_URL` (from your Render PostgreSQL database)
- `DB_USER` (from your Render PostgreSQL database)
- `DB_PASS` (from your Render PostgreSQL database)
- `OLLAMA_BASE_URL` (if using external Ollama)
- `OLLAMA_MODEL` (optional, defaults to llama3)

---

## Troubleshooting

### Build Fails: "Cannot find mvnw"

**Solution**: Ensure you're in the project root directory and that `mvnw` exists.

```bash
ls -la mvnw
```

### Build Fails: Network Timeout

**Solution**: Check your internet connection. Maven needs to download dependencies.

### Container Exits Immediately

**Check logs**:
```bash
docker logs <container-id>
```

**Common causes**:
- Database connection failed (check DB_URL, DB_USER, DB_PASS)
- Required environment variables missing
- Port already in use

### Port Already in Use

**Solution**: Use a different port:
```bash
docker run -p 8081:8080 sentiment-analysis-service
```

### Database Connection Issues

**Test database connectivity**:
```bash
# From inside container
docker exec -it <container-id> sh
# Then test connection (if you have psql installed)
```

**Common issues**:
- Database host not accessible from container
- Wrong credentials
- Database not running

### Memory Issues

The Dockerfile sets `-Xms512m -Xmx1024m`. To change:

**Option 1**: Build with build arg:
```bash
docker build --build-arg JAVA_OPTS="-Xms256m -Xmx512m" -t sentiment-analysis-service .
```

**Option 2**: Override at runtime:
```bash
docker run -e JAVA_OPTS="-Xms256m -Xmx512m" sentiment-analysis-service
```

---

## Image Size Optimization

The Dockerfile uses a multi-stage build to minimize final image size:
- **Build stage**: ~500MB+ (includes JDK, Maven, source code)
- **Runtime stage**: ~200MB (just JRE + JAR file)

Final image size should be around **200-250MB**.

---

## Security Notes

✅ **Already Implemented**:
- Runs as non-root user (`spring:spring`)
- Multi-stage build (reduces attack surface)
- Minimal runtime image (only JRE)

⚠️ **Remember**:
- Never hardcode credentials in Dockerfile or source code
- Use environment variables or secrets management
- Keep base images updated
- Scan images for vulnerabilities: `docker scan sentiment-analysis-service`

---

## Quick Reference Commands

```bash
# Build
docker build -t sentiment-analysis-service .

# Run (basic)
docker run -p 8080:8080 sentiment-analysis-service

# Run (with env vars)
docker run -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e DB_URL=... -e DB_USER=... -e DB_PASS=... \
  sentiment-analysis-service

# Run (detached)
docker run -d -p 8080:8080 --name sentiment-api sentiment-analysis-service

# View logs
docker logs sentiment-api

# Stop
docker stop sentiment-api

# Remove
docker rm sentiment-api

# Remove image
docker rmi sentiment-analysis-service

# List images
docker images

# List containers
docker ps
```

---

## Next Steps

1. **Test locally**: Build and run the Docker image locally first
2. **Set up environment variables**: Configure all required environment variables
3. **Deploy to Render**: Connect your repository and let Render build automatically
4. **Monitor**: Use `docker logs` or Render's logs to monitor the application

For questions or issues, refer to the [REPOSITORY_REVIEW.md](./REPOSITORY_REVIEW.md) file.


