package com.school_event.school_event_management.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.access.intercept.AuthorizationFilter;
import org.springframework.security.web.authentication.HttpStatusEntryPoint;

import com.school_event.school_event_management.repository.userAccountRepository;
import com.school_event.school_event_management.security.ActiveAccountFilter;

import jakarta.servlet.http.HttpServletResponse;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http,
                                                   userAccountRepository users) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                // Spring forwards failed requests to /error; without this,
                // an anonymous CSRF failure would show up as 401 instead of 403.
                .requestMatchers("/error").permitAll()
                .requestMatchers("/api/auth/csrf", "/api/auth/login").permitAll()
                // Venues: both roles read, only Event Organizers write.
                .requestMatchers(HttpMethod.GET, "/api/venues/**")
                        .hasAnyRole("SUPER_ADMIN", "EVENT_ORGANIZER")
                .requestMatchers("/api/venues/**").hasRole("EVENT_ORGANIZER")
                // Events: both roles read, only Event Organizers write.
                .requestMatchers(HttpMethod.GET, "/api/events/**")
                        .hasAnyRole("SUPER_ADMIN", "EVENT_ORGANIZER")
                .requestMatchers("/api/events/**").hasRole("EVENT_ORGANIZER")
                // Audit log: Super Admin only (read-only through the API).
                .requestMatchers("/api/audit-logs/**").hasRole("SUPER_ADMIN")
                // User management: Super Admin only.
                .requestMatchers("/api/users/**").hasRole("SUPER_ADMIN")
                // /api/account/** (own profile and password): any logged-in user.
                .anyRequest().authenticated())
            .formLogin(form -> form
                // Setting loginPage turns off Spring's built-in HTML login page.
                .loginPage("/api/auth/login")
                .loginProcessingUrl("/api/auth/login")
                .successHandler((request, response, authentication) ->
                        response.setStatus(HttpServletResponse.SC_NO_CONTENT))
                .failureHandler((request, response, exception) -> {
                    // One generic message for every failure (unknown user,
                    // wrong password, inactive account).
                    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                    response.getWriter().write("{\"status\":401,\"error\":\"Unauthorized\","
                            + "\"message\":\"Invalid username or password.\"}");
                }))
            .logout(logout -> logout
                .logoutUrl("/api/auth/logout")
                .logoutSuccessHandler((request, response, authentication) ->
                        response.setStatus(HttpServletResponse.SC_NO_CONTENT)))
            // Anonymous requests to protected URLs get a plain 401, not a redirect.
            .exceptionHandling(ex -> ex
                .authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)))
            // Re-check the logged-in account before any access decision is made.
            .addFilterBefore(new ActiveAccountFilter(users), AuthorizationFilter.class);
        // CSRF protection stays ON (the default).
        return http.build();
    }
}