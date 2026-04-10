---
name: security-check
description: Analyse project for injection vulnerabilities, broken auth, data exposure, config issues, dependency CVEs, and multi-tenancy security gaps
argument-hint: "[optional: specific file, feature, or area to check]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob
---

# Security Vulnerability Analysis

Analyse the project for common security vulnerabilities and misconfigurations. Not a replacement for a proper security audit, but catches the most common issues.

## Scope

If `$ARGUMENTS` specifies a file or feature, focus there. Otherwise scan the entire project.

## Analysis Categories

### 1. Injection Vulnerabilities

- **SQL Injection**: String concatenation in SQL queries, raw SQL without parameterisation, dynamic query construction.
- **XSS**: Unescaped user input in responses, missing Content-Type headers, raw HTML rendering.
- **Command Injection**: `Runtime.exec()` or `ProcessBuilder` with user input.
- **LDAP/NoSQL Injection**: Unparameterised queries against LDAP or NoSQL databases.

### 2. Authentication and Authorisation

- **Missing authentication**: Endpoints not protected by Spring Security.
- **Broken access control**: Endpoints not verifying tenant ID or user permissions.
- **JWT issues**: Validation correctly configured, tokens validated on every request, secrets not hardcoded.
- **Session management**: Stateless session configuration confirmed.

### 3. Data Exposure

- **Sensitive data in logs**: Passwords, tokens, API keys, or PII.
- **Sensitive data in responses**: Entity fields leaking to API responses (tenant ID, internal IDs, audit fields).
- **Error message leakage**: 500 errors returning stack traces or internal details.
- **Sensitive data in URLs**: Sensitive information in query parameters or path variables.

### 4. Configuration Security

- **Hardcoded secrets**: API keys, passwords, or tokens in source code or config files.
- **Default credentials**: Unchanged default passwords.
- **CORS configuration**: Not wildcard `*` in production.
- **CSRF protection**: Disabled only for stateless APIs.
- **Security headers**: CSP, X-Content-Type-Options, X-Frame-Options, HSTS.

### 5. Dependency Vulnerabilities

- Known vulnerable versions in `pom.xml` or `package.json`.
- Outdated dependencies with known CVEs.
- Unnecessary dependencies that increase attack surface.

### 6. Multi-Tenancy Security

- **Tenant isolation**: Every database query filters by tenant ID.
- **Cross-tenant access**: Endpoints or service methods that could return another tenant's data.
- **Tenant ID source**: From JWT claims, not request parameters.

### 7. Input Handling

- **Missing validation**: Request DTOs without Bean Validation annotations.
- **Unbounded inputs**: String fields without `@Size`, collections without `@Size`, numerics without range constraints.
- **File upload security**: File type validation, size limits, path traversal prevention (if applicable).

## Output Format

```
## Security Analysis Report

**Risk Level:** [LOW | MEDIUM | HIGH | CRITICAL]

### Critical Issues (Fix Immediately)
- [Issue description, location, and remediation]

### High Priority
- [Issue description, location, and remediation]

### Medium Priority
- [Issue description, location, and remediation]

### Low Priority / Informational
- [Issue description and recommendation]

### Positive Findings
- [Security practices already implemented correctly]
```

Each finding includes:
1. **What**: Description of the vulnerability
2. **Where**: File path and line reference
3. **Risk**: What could happen if exploited
4. **Fix**: Specific code change to remediate
