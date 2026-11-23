package com.afab.invoices.service;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Generates concurrency-safe unique sequential invoice numbers per Business and Year
 * using PostgreSQL atomic UPSERT (`INSERT ... ON CONFLICT DO UPDATE ... RETURNING`).
 */
@Service
public class InvoiceNumberGenerator {

    private final JdbcTemplate jdbcTemplate;

    public InvoiceNumberGenerator(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Transactional
    public String nextInvoiceNumber(UUID businessId, int year) {
        Long seq = jdbcTemplate.queryForObject(
                """
                INSERT INTO invoice_sequences (business_id, year, last_number)
                VALUES (?, ?, 1)
                ON CONFLICT (business_id, year)
                DO UPDATE SET last_number = invoice_sequences.last_number + 1
                RETURNING last_number
                """,
                Long.class,
                businessId,
                year
        );
        long num = seq != null ? seq : 1L;
        return String.format("INV-%d-%04d", year, num);
    }
}
