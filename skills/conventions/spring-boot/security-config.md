# Spring Security, Actuator, and Multi-Tenancy

## Security Configuration

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/actuator/health", "/actuator/info").permitAll()
                .requestMatchers("/api/v1/**").authenticated()
                .anyRequest().denyAll())
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthConverter())));

        return http.build();
    }

    private JwtAuthenticationConverter jwtAuthConverter() {
        JwtGrantedAuthoritiesConverter authoritiesConverter = new JwtGrantedAuthoritiesConverter();
        authoritiesConverter.setAuthoritiesClaimName("realm_access.roles");
        authoritiesConverter.setAuthorityPrefix("ROLE_");

        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(authoritiesConverter);
        return converter;
    }
}
```

## Security Rules

- Stateless sessions only. No server-side session storage.
- CSRF disabled for stateless API (JWT in Authorization header).
- Default deny — explicit allow only for known endpoints.
- Health and info endpoints are public. Everything under `/api/` requires authentication.
- Extract tenant ID from JWT token claims. Never from request parameters, headers, or path variables.
- Use `@PreAuthorize` for endpoint-level authorization when roles are needed.

---

## Actuator

```properties
management.endpoints.web.exposure.include=health, info, metrics, prometheus
management.endpoint.health.show-details=when-authorized
management.health.db.enabled=false
management.health.diskspace.enabled=true
```

- Expose only necessary actuator endpoints.
- Health check shows details only to authenticated users.
- Database health checks disabled by default; the database layer enables them.
- Add custom health indicators for critical dependencies (Kafka, external APIs).
- Expose Prometheus metrics endpoint for monitoring.

---

## Multi-Tenancy

### TenantInterceptor

```java
@Component
public class TenantInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest request,
                             HttpServletResponse response,
                             Object handler) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth instanceof JwtAuthenticationToken jwt) {
            String tenantId = jwt.getToken().getClaimAsString("tenant_id");
            TenantContext.setCurrentTenant(tenantId);
        }
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request,
                                HttpServletResponse response,
                                Object handler, Exception ex) {
        TenantContext.clear();
    }
}
```

### TenantContext

```java
public final class TenantContext {

    private static final ThreadLocal<String> CURRENT_TENANT = new ThreadLocal<>();

    private TenantContext() {}

    public static String getCurrentTenant() { return CURRENT_TENANT.get(); }

    public static void setCurrentTenant(String tenantId) { CURRENT_TENANT.set(tenantId); }

    public static void clear() { CURRENT_TENANT.remove(); }
}
```

## Multi-Tenancy Rules

- Tenant ID comes from the JWT token only. Never from request parameters, headers, or path variables.
- Every data access operation includes a tenant filter. The database layer specifies how.
- Every domain object includes a `tenantId` field.
- Test with multiple tenants in integration tests to verify data isolation.
- Tenant context is set in an interceptor and cleared after the request completes. Always clear to prevent thread-local leakage.
