package com.afab;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

/**
 * AFAB — AI Finance Assistant for Business.
 * Entry point for the Spring Boot 4.1 backend.
 */
@SpringBootApplication
@EnableAsync
public class AfabApplication {

    public static void main(String[] args) {
        SpringApplication.run(AfabApplication.class, args);
    }
}
