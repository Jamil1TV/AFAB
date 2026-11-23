package com.afab.config;

import org.flywaydb.core.Flyway;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.sql.DataSource;

@Configuration
public class FlywayConfig {

    @Value("${spring.flyway.locations:classpath:db/migration}")
    private String locations;

    @Value("${afab.flyway.repair-on-migrate:false}")
    private boolean repairOnMigrate;

    @Bean(initMethod = "migrate")
    public Flyway flyway(DataSource dataSource) {
        Flyway flyway = Flyway.configure()
                .dataSource(dataSource)
                .locations(locations)
                .baselineOnMigrate(true)
                .load();
        if (repairOnMigrate) {
            flyway.repair();
        }
        return flyway;
    }
}

