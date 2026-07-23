package com.afab.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * OpenAPI / Swagger UI configuration.
 */
@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI afabOpenAPI() {
        // Define the security scheme for JWT Bearer token
        SecurityScheme securityScheme = new SecurityScheme()
                .name("Bearer Authentication")
                .type(SecurityScheme.Type.HTTP)
                .scheme("bearer")
                .bearerFormat("JWT");

        return new OpenAPI()
                .info(new Info()
                        .title("AFAB API")
                        .description("AI Finance Assistant for Business — REST API")
                        .version("1.0.0")
                        .contact(new Contact()
                                .name("AFAB Team")
                                .email("support@afab.local")))
                // Add the security scheme to the OpenAPI components
                .components(new Components().addSecuritySchemes("bearerAuth", securityScheme))
                // Apply the security scheme globally to all endpoints
                .addSecurityItem(new SecurityRequirement().addList("bearerAuth"));
    }
}
