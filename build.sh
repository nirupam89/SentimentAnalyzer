#!/usr/bin/env bash
# Build script for Render deployment
# This script builds the Spring Boot application into an executable JAR file

set -o errexit  # Exit on error

set -o pipefail # Exit on pipe failure

echo "Building Spring Boot application..."
mvn clean package -DskipTests

echo "Build completed successfully!"
echo "Artifact location: target/sentiment-analysis-service-0.0.1-SNAPSHOT.jar"

