package com.afab.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

/**
 * OpenAPI / Swagger UI configuration.
 * Generates the API contract consumed by the frontend typed client.
 */
@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI afabOpenApi() {
        final String securitySchemeName = "BearerAuth";

        return new OpenAPI()
                .info(new Info()
                        .title("AFAB API")
                        .description("AI Finance Assistant for Business — REST API Documentation")
                        .version("1.0.0")
                        .contact(new Contact()
                                .name("AFAB Team")
                                .email("team@afab.local"))
                        .license(new License()
                                .name("Proprietary")
                                .url("https://afab.local")))
                .servers(List.of(
                        new Server()
                                .url("http://localhost:8080")
                                .description("Local Development")))
                .addSecurityItem(new SecurityRequirement()
                        .addList(securitySchemeName))
                .components(new Components()
                        .addSecuritySchemes(securitySchemeName,
                                new SecurityScheme()
                                        .name(securitySchemeName)
                                        .type(SecurityScheme.Type.HTTP)
                                        .scheme("bearer")
                                        .bearerFormat("JWT")
                                        .description("Enter your JWT access token")));
    }
}
