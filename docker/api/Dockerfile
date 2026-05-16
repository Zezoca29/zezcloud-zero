# =============================================================================
# Multi-stage build — produces a minimal production image
# =============================================================================

# ─── Stage 1: Build ───────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /build

# Cache dependencies before copying source
COPY pom.xml .
COPY .mvn/ .mvn/
COPY mvnw .

RUN chmod +x mvnw && ./mvnw dependency:go-offline -q

# Copy source and build
COPY src/ src/
RUN ./mvnw clean package -DskipTests -q

# ─── Stage 2: Extract layers (Spring Boot layered jar) ────────────────────────
FROM eclipse-temurin:21-jdk-alpine AS extractor

WORKDIR /extracted
COPY --from=builder /build/target/*.jar app.jar
RUN java -Djarmode=layertools -jar app.jar extract

# ─── Stage 3: Runtime ─────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine AS runtime

# Security: non-root user
RUN addgroup --system zezcloud && adduser --system --ingroup zezcloud zezcloud

WORKDIR /app

# Copy layered jar contents (optimizes Docker cache for dependencies)
COPY --from=extractor /extracted/dependencies/          ./
COPY --from=extractor /extracted/spring-boot-loader/    ./
COPY --from=extractor /extracted/snapshot-dependencies/ ./
COPY --from=extractor /extracted/application/           ./

USER zezcloud

ARG SPRING_PROFILE=prod
ENV SPRING_PROFILES_ACTIVE=${SPRING_PROFILE}
ENV JAVA_OPTS="-Xms128m -Xmx256m -XX:+UseContainerSupport -XX:MaxRAMPercentage=75"

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=45s --retries=3 \
    CMD wget -qO- http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS org.springframework.boot.loader.launch.JarLauncher"]
