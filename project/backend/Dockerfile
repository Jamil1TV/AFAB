# syntax=docker/dockerfile:1.7
# ─────────────────────────────────────────────────────────────
# IMPORTANT : The build context is the PROJECT ROOT (project/),
# because the Maven build might need OpenAPI contracts in ../contracts.
# Build with :
#   docker build -f backend/Dockerfile -t afab-backend .
# (the final "." = root of the project, not the backend/ folder)
# ─────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────
# Stage 1 — Build (Maven + JDK 21)
# ─────────────────────────────────────────────────────────────
FROM maven:3.9.9-eclipse-temurin-21 AS build
WORKDIR /workspace

# Contracts are copied in case OpenAPI generation is needed
COPY contracts/ contracts/

# Maven descriptor first: as long as pom.xml doesn't change, dependencies
# remain in the layer cache and are not re-downloaded.
COPY backend/pom.xml backend/pom.xml
RUN --mount=type=cache,target=/root/.m2 mvn -f backend/pom.xml dependency:go-offline -B

# Source code then build. Tests run in CI, not in the image.
COPY backend/src backend/src
RUN --mount=type=cache,target=/root/.m2 mvn -f backend/pom.xml clean package -DskipTests -B \
    && java -Djarmode=layertools -jar backend/target/*.jar extract \
       --destination backend/target/extracted

# ─────────────────────────────────────────────────────────────
# Stage 2 — Runtime (JRE only, minimal image)
# ─────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine AS runtime
WORKDIR /app

# Non-root user for security
RUN addgroup -S spring && adduser -S spring -G spring -u 1000
USER spring:spring

# Copy Spring Boot layers separately (better cache on redeployment)
ARG EXTRACTED=/workspace/backend/target/extracted
COPY --from=build --chown=spring:spring ${EXTRACTED}/dependencies/ ./
COPY --from=build --chown=spring:spring ${EXTRACTED}/spring-boot-loader/ ./
COPY --from=build --chown=spring:spring ${EXTRACTED}/snapshot-dependencies/ ./
COPY --from=build --chown=spring:spring ${EXTRACTED}/application/ ./

# Exposed port
EXPOSE 8080

# JVM settings adapted for containers
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -XX:+UseG1GC -XX:+ExitOnOutOfMemoryError"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health | grep -q UP || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS org.springframework.boot.loader.launch.JarLauncher"]
