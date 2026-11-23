package com.afab.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

import java.util.Arrays;

@Component
public class StartupLogger {

    private static final Logger log = LoggerFactory.getLogger(StartupLogger.class);

    private final Environment environment;

    @Value("${server.port:8080}")
    private String serverPort;

    public StartupLogger(Environment environment) {
        this.environment = environment;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void onApplicationReady() {
        String profiles = environment.getActiveProfiles().length > 0
                ? String.join(", ", Arrays.asList(environment.getActiveProfiles()))
                : "default";

        String banner = """

                ================================================================

                     █████╗ ███████╗ █████╗ ██████╗
                    ██╔══██╗██╔════╝██╔══██╗██╔══██╗
                    ███████║█████╗  ███████║██████╔╝
                    ██╔══██║██╔══╝  ██╔══██║██╔══██╗
                    ██║  ██║██║     ██║  ██║██████╔╝
                    ╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═════╝

                  🚀  AFAB BACKEND & DATABASE STARTED — READY!  🚀
                ----------------------------------------------------------------
                  ✅  Database   : Connected & Flyway Migrated
                  ✅  Security   : Auth & Protection Active
                  ✅  Profile    : %s
                  ✅  API URL    : http://localhost:%s
                  ✅  Swagger UI : http://localhost:%s/swagger-ui.html
                ================================================================
                """.formatted(profiles, serverPort, serverPort);

        log.info(banner);
    }
}
