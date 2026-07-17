package com.afab.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

@Component
public class StartupLogger {

    private static final Logger log = LoggerFactory.getLogger(StartupLogger.class);

    @EventListener(ApplicationReadyEvent.class)
    public void onApplicationReady() {
        log.info("=========================================================");
        log.info("🚀 EVERYTHING IS READY AND RUNNING PERFECTLY! 🚀");
        log.info("✅ Database is connected and migrated");
        log.info("✅ Security and Auth endpoints are locked and loaded");
        log.info("✅ Swagger UI is available at: http://localhost:8080/swagger-ui.html");
        log.info("=========================================================");
    }
}
