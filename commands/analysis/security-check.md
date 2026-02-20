# Security Vulnerability Analysis

Analyse the project for common security vulnerabilities and misconfigurations. This is not a replacement for a proper security audit but catches the most common issues.

## Analysis Categories

### 1. Injection Vulnerabilities

- **SQL Injection**: Scan for string concatenation in SQL queries, raw SQL without parameterisation, and dynamic query construction without proper escaping.
- **XSS**: Check for unescaped user input in responses, missing Content-Type headers, and raw HTML rendering.
- **Command Injection**: Look for Runtime.exec() or ProcessBuilder with user input.
- **LDAP/NoSQL Injection**: Check for unparameterised queries against LDAP or NoSQL databases.

### 2. Authentication and Authorisation

- **Missing authentication**: Identify endpoints not protected by Spring Security.
- **Broken access control**: Check for endpoints that do not verify tenant ID or user permissions.
- **JWT issues**: Verify JWT validation is configured correctly, tokens are validated on every request, and secrets are not hardcoded.
- **Session management**: Confirm stateless session configuration.

### 3. Data Exposure

- **Sensitive data in logs**: Scan for logging of passwords, tokens, API keys, or PII.
- **Sensitive data in responses**: Check for entity fields leaking to API responses (tenant ID, internal IDs, audit fields that should be hidden).
- **Error message leakage**: Verify that 500 errors return generic messages without stack traces or internal details.
- **Sensitive data in URLs**: Check for sensitive information in query parameters or path variables.

### 4. Configuration Security

- **Hardcoded secrets**: Scan for API keys, passwords, or tokens in source code, configuration files, or test files.
- **Default credentials**: Check for unchanged default passwords in configuration.
- **CORS configuration**: Verify CORS is properly configured (not wildcard `*` in production).
- **CSRF protection**: Confirm CSRF is disabled only for stateless APIs, not for session-based endpoints.
- **Security headers**: Check for Content-Security-Policy, X-Content-Type-Options, X-Frame-Options, Strict-Transport-Security headers.

### 5. Dependency Vulnerabilities

- Check `pom.xml` / `package.json` for known vulnerable versions.
- Flag outdated dependencies that have known CVEs.
- Identify unnecessary dependencies that increase attack surface.

### 6. Multi-Tenancy Security

- **Tenant isolation**: Verify every database query filters by tenant ID.
- **Cross-tenant access**: Check for endpoints or service methods that could return data from another tenant.
- **Tenant ID source**: Confirm tenant ID comes from JWT claims, not from request parameters.

### 7. Input Handling

- **Missing validation**: Identify request DTOs without Bean Validation annotations.
- **Unbounded inputs**: Check for string fields without `@Size` limits, collections without `@Size` limits, numeric fields without range constraints.
- **File upload security**: If applicable, check for file type validation, size limits, and storage path traversal prevention.

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

Report each finding with:
1. **What**: Description of the vulnerability
2. **Where**: File path and line reference
3. **Risk**: What could happen if exploited
4. **Fix**: Specific code change to remediate
