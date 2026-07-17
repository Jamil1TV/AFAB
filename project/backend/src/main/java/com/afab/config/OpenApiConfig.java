package com.afab.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * OpenAPI / Swagger UI configuration.
 */
@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI afabOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("AFAB API")
                        .description("AI Finance Assistant for Business — REST API")
                        .version("1.0.0")
                        .contact(new Contact()
                                .name("AFAB Team")
                                .email("support@afab.local")));
    }
}
