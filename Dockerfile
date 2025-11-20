# ------------------------------------
# Stage 1: Build Stage (Uses a full JDK to compile and package the JAR file)
# ------------------------------------
FROM openjdk:17-jdk-slim AS build

# Set the working directory inside the container
WORKDIR /app

# Copy Maven wrapper and pom.xml to set up the build context
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Make Maven wrapper executable
RUN chmod +x mvnw

# Fetch dependencies first (speeds up rebuilds if dependencies haven't changed)
RUN ./mvnw dependency:go-offline

# Copy the rest of the source code
COPY src /app/src

# Package the application into a single executable JAR file
RUN ./mvnw clean package -DskipTests

# Verify the JAR file was created
RUN ls -la /app/target/*.jar

# ------------------------------------
# Stage 2: Production/Runtime Stage (Uses simple JRE image)
# ------------------------------------
# We use a lightweight JRE image since Spring Boot JAR includes embedded Tomcat
# Spring Boot JAR files can run standalone with 'java -jar'
FROM eclipse-temurin:17-jre-jammy

# Set environment variables for production
ENV SPRING_PROFILES_ACTIVE=prod
ENV JAVA_OPTS="-Djava.awt.headless=true -Xms512m -Xmx1024m"

# Create a non-root user for security
RUN groupadd -r spring && useradd -r -g spring spring

# Set working directory
WORKDIR /app

# Copy the built JAR file from the 'build' stage
COPY --from=build /app/target/sentiment-analysis-service-0.0.1-SNAPSHOT.jar app.jar

# Change ownership to non-root user
RUN chown spring:spring app.jar

# Switch to non-root user
USER spring:spring

# Expose port 8080 (Spring Boot default, can be overridden with PORT env var)
EXPOSE 8080

# Run the Spring Boot JAR file with embedded Tomcat
# The PORT environment variable will be respected by Spring Boot
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
