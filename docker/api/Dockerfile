# =============================================================================
# Multi-stage build — produces a minimal production image
# Uses Maven image (no mvnw needed)
# =============================================================================

# ─── Stage 1: Build ───────────────────────────────────────────────────────────
FROM maven:3.9-eclipse-temurin-21-alpine AS builder

WORKDIR /build

COPY pom.xml .
RUN mvn dependency:go-offline -q

COPY src/ src/
RUN mvn clean package -DskipTests -q

# ─── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine AS runtime

RUN addgroup --system zezcloud && adduser --system --ingroup zezcloud zezcloud

WORKDIR /app

ARG SPRING_PROFILE=dev
ENV SPRING_PROFILES_ACTIVE=${SPRING_PROFILE}
ENV JAVA_OPTS="-Xms128m -Xmx256m -XX:+UseContainerSupport"

COPY --from=builder /build/target/*.jar app.jar

RUN chown zezcloud:zezcloud app.jar
USER zezcloud

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=45s --retries=3 \
    CMD wget -qO- http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

