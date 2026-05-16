# Architecture Decision Records

## ADR-001: PostgreSQL em Container em vez de RDS

**Status:** Accepted

**Context:** RDS PostgreSQL custa mínimo ~$15/mês mesmo no tier mais barato (db.t3.micro), além de cobranças por storage e backups.

**Decision:** PostgreSQL containerizado via Docker com volume persistente no mesmo EC2.

**Consequences:**
- ✅ Custo zero
- ✅ Mesma interface JDBC/SQL — API não sabe a diferença
- ✅ Migração futura para RDS: apenas muda connection string
- ⚠️ Sem Multi-AZ (aceitável para portfólio)
- ⚠️ Backup manual necessário (script via cron ou S3)

---

## ADR-002: Nginx em vez de ALB

**Status:** Accepted

**Context:** Application Load Balancer custa ~$16/mês fixo + $0.008 por LCU-hora.

**Decision:** Nginx como reverse proxy no mesmo EC2, proxying para containers internos.

**Consequences:**
- ✅ Custo zero
- ✅ Demonstra conhecimento de Nginx (valioso em entrevistas)
- ✅ Rate limiting, headers de segurança, gzip — todos configurados
- ⚠️ Sem load balancing multi-instância (não necessário neste escopo)

---

## ADR-003: Docker Compose em vez de ECS

**Status:** Accepted

**Context:** ECS Fargate cobra por CPU/memória por segundo. ECS EC2 adiciona complexidade sem benefício no Free Tier.

**Decision:** Docker Compose no EC2 t2.micro.

**Consequences:**
- ✅ Custo zero
- ✅ docker-compose.yml é portável e demonstra conhecimento de containers
- ✅ Migração futura para ECS: converter compose para task definitions
- ⚠️ Sem orquestração automática (Kubernetes seria a evolução natural)

---

## ADR-004: GitHub OIDC em vez de IAM Access Keys

**Status:** Accepted

**Context:** Armazenar AWS access keys no GitHub é risco de segurança. Se o secret vazar, a conta AWS fica exposta.

**Decision:** GitHub Actions assume IAM role via OIDC (Web Identity Federation). Nenhuma chave de longa duração armazenada no GitHub.

**Consequences:**
- ✅ Zero long-lived credentials no GitHub
- ✅ Role com permissões mínimas por ambiente
- ✅ Audit trail completo no CloudTrail
- ✅ Demonstra conhecimento avançado de IAM/OIDC

---

## ADR-005: Cloudflare em vez de ACM + ALB para SSL

**Status:** Accepted

**Context:** ACM sozinho é gratuito, mas requer ALB (~$16/mês) para terminar SSL em EC2.

**Decision:** Cloudflare Free Tier gerencia DNS + SSL, proxies para o Elastic IP.

**Consequences:**
- ✅ Custo zero para SSL/DNS
- ✅ DDoS protection incluída no Free Tier
- ✅ Global CDN cache
- ✅ Demonstra conhecimento de Cloudflare (muito usado em produção)
