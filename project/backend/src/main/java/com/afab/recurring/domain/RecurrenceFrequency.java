package com.afab.recurring.domain;

import java.time.LocalDate;

public enum RecurrenceFrequency {
    WEEKLY,
    MONTHLY,
    QUARTERLY,
    YEARLY;

    public LocalDate nextDate(LocalDate from) {
        return switch (this) {
            case WEEKLY -> from.plusWeeks(1);
            case MONTHLY -> from.plusMonths(1);
            case QUARTERLY -> from.plusMonths(3);
            case YEARLY -> from.plusYears(1);
        };
    }
}
