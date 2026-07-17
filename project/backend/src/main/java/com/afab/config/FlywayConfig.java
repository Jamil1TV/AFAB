package com.afab.config;

import org.flywaydb.core.Flyway;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.sql.DataSource;

@Configuration
public class FlywayConfig {

    @Value("${spring.flyway.url}")
    private String url;

    @Value("${spring.flyway.user}")
    private String user;

    @Value("${spring.flyway.password}")
    private String password;

    @Value("${spring.flyway.locations}")
    private String locations;

    @Bean(initMethod = "migrate")
    public Flyway flyway(DataSource dataSource) {
        return Flyway.configure()
                .dataSource(url, user, password)
                .locations(locations)
                .baselineOnMigrate(true)
                .load();
    }
}
