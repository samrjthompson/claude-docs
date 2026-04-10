---
name: dependency-check
description: Review project dependencies for outdated versions, known vulnerabilities, unnecessary inclusions, missing version pinning, and licence concerns
disable-model-invocation: true
allowed-tools: Read, Glob
---

# Dependency Health Check

Review project dependencies for outdated versions, known vulnerabilities, unnecessary inclusions, and maintenance status.

## Analysis Scope

Examine:
- `pom.xml` (Maven dependencies for Spring Boot / Spark)
- `package.json` (npm dependencies for React)

## Check Categories

### 1. Outdated Dependencies

For each dependency:
- Is a newer minor or patch version available?
- Is a newer major version available? What are the breaking changes?
- Is the current version still receiving security patches?

Flag as:
- **OUTDATED**: Newer version available with no breaking changes.
- **MAJOR UPDATE**: Newer major version available, migration needed.
- **END OF LIFE**: Version no longer maintained.

### 2. Known Vulnerabilities

Cross-reference versions against known CVEs:
- Published security advisories for direct dependencies.
- Transitive dependencies that may introduce vulnerabilities.
- Severity: CRITICAL, HIGH, MEDIUM, LOW.

### 3. Unnecessary Dependencies

Identify:
- Dependencies imported but never used in code.
- Overlapping functionality (multiple HTTP clients, multiple JSON libraries).
- Dependencies pulled in for a single utility that could be written inline.
- Test dependencies leaking into production scope.

### 4. Dependency Hygiene

Check for:
- Dependencies without version pinning (dynamic version ranges).
- SNAPSHOT dependencies in production configuration.
- Dependencies from unrecognised or low-adoption sources.
- Excessively large dependencies for their purpose.

### 5. Licence Compliance

Flag:
- GPL or AGPL licences (may be incompatible with proprietary software).
- Missing licence information.
- Licences requiring attribution.

## Output Format

```
## Dependency Health Report

**Overall Health:** [HEALTHY | NEEDS ATTENTION | AT RISK]

### Critical Updates Needed
| Dependency | Current | Latest | Severity | Reason |
|-----------|---------|--------|----------|--------|
| lib-name | 1.2.3 | 1.2.5 | HIGH | CVE-2024-XXXXX |

### Recommended Updates
| Dependency | Current | Latest | Type | Notes |
|-----------|---------|--------|------|-------|
| lib-name | 2.0.0 | 2.3.1 | Minor | Bug fixes and performance |

### Unnecessary Dependencies
- `dep-name`: [Reason it may be unnecessary]

### Licence Concerns
- `dep-name` (GPL-3.0): [Action needed]

### Summary Statistics
- Total dependencies: X
- Up to date: X
- Outdated: X
- Vulnerable: X
```
