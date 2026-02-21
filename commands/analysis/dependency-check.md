# Dependency Health Check

Review project dependencies for outdated versions, known vulnerabilities, unnecessary inclusions, and maintenance status.

## Analysis Scope

Examine:
- `pom.xml` (Maven dependencies for Spring Boot)
- `package.json` (npm dependencies for React)
- `pom.xml` (Maven dependencies for Spark/Java, if present)

## Check Categories

### 1. Outdated Dependencies

For each dependency, check:
- Is a newer minor or patch version available?
- Is a newer major version available? If so, what are the breaking changes?
- Is the current version still receiving security patches?

Flag as:
- **OUTDATED**: Newer version available with no breaking changes.
- **MAJOR UPDATE**: Newer major version available, migration needed.
- **END OF LIFE**: Version is no longer maintained.

### 2. Known Vulnerabilities

Cross-reference dependency versions against known CVE databases:
- Check for dependencies with published security advisories.
- Identify transitive dependencies that may introduce vulnerabilities.
- Flag severity: CRITICAL, HIGH, MEDIUM, LOW.

### 3. Unnecessary Dependencies

Identify dependencies that may not be needed:
- Dependencies imported but never used in code.
- Dependencies that overlap in functionality (e.g., multiple HTTP clients, multiple JSON libraries).
- Dependencies pulled in for a single utility function that could be written inline.
- Test dependencies that are leaking into production scope.

### 4. Dependency Hygiene

Check for:
- Dependencies without version pinning (dynamic version ranges).
- SNAPSHOT dependencies in production configuration.
- Dependencies not from trusted sources (unknown group IDs, unpopular libraries).
- Excessively large dependencies for their purpose.

### 5. Licence Compliance

Flag dependencies with:
- GPL or AGPL licences (may be incompatible with proprietary software).
- Missing licence information.
- Licences that require attribution (ensure NOTICE file is up to date).

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
