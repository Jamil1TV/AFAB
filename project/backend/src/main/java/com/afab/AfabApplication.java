package com.afab;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * AFAB — AI Finance Assistant for Business
 * Main application entry point.
 */
@SpringBootApplication
@EnableScheduling
public class AfabApplication {

    public static void main(String[] args) {
        SpringApplication.run(AfabApplication.class, args);
    }
}
