package com.afab.ai;

import com.afab.ai.service.AiLanguageResolver;
import com.afab.ai.service.AiLanguageResolver.AiLanguage;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class AiLanguageResolverTest {

    private final AiLanguageResolver resolver = new AiLanguageResolver();

    @Test
    @DisplayName("Detects all 5 language/dialect modes and handles explicit mid-chat switching")
    void detectsAllModesAndSwitches() {
        assertThat(resolver.resolveLanguage("How much did I spend this month?", null, "en"))
                .isEqualTo(AiLanguage.EN);
        assertThat(resolver.resolveLanguage("Combien ai-je dépensé ce mois-ci pour les factures ?", AiLanguage.EN, "en"))
                .isEqualTo(AiLanguage.FR);
        assertThat(resolver.resolveLanguage("ما هي الفواتير المتأخرة هذا الشهر؟", AiLanguage.EN, "en"))
                .isEqualTo(AiLanguage.AR_MSA);
        assertThat(resolver.resolveLanguage("قداش صرفت هذا الشهر وشنية أكثر المصاريف؟", AiLanguage.EN, "en"))
                .isEqualTo(AiLanguage.AR_DERJA_SCRIPT);
        assertThat(resolver.resolveLanguage("Khalast 145 TND essence lbereh cash, kadeh sraft hal chhar?", AiLanguage.EN, "en"))
                .isEqualTo(AiLanguage.AR_DERJA_ARABIZI);

        assertThat(resolver.resolveLanguage("jawebni b tounsi please", AiLanguage.EN, "en"))
                .isEqualTo(AiLanguage.AR_DERJA_ARABIZI);
        assertThat(resolver.resolveLanguage("Réponds en anglais s'il te plaît, in english", AiLanguage.FR, "fr"))
                .isEqualTo(AiLanguage.EN);
    }

    @Test
    @DisplayName("Preserves sticky conversation language across short or ambiguous turns")
    void stickyContinuityOnShortTurns() {
        assertThat(resolver.resolveLanguage("ok", AiLanguage.FR, "en")).isEqualTo(AiLanguage.FR);
        assertThat(resolver.resolveLanguage("1200", AiLanguage.AR_DERJA_ARABIZI, "en")).isEqualTo(AiLanguage.AR_DERJA_ARABIZI);
        assertThat(resolver.resolveLanguage("", AiLanguage.AR_MSA, "en")).isEqualTo(AiLanguage.AR_MSA);
    }

    @Test
    @DisplayName("Flags English boilerplate meta-replies when target language is not English")
    void mismatchRepairGuard() {
        assertThat(resolver.needsLanguageRepair(
                AiLanguage.AR_DERJA_ARABIZI,
                "I can communicate in Tunisian Derja! Here is a summary of your expenses."
        )).isTrue();
        assertThat(resolver.needsLanguageRepair(
                AiLanguage.FR,
                "Voici votre résumé des dépenses et revenus pour ce mois-ci."
        )).isFalse();
        assertThat(resolver.localizedFollowUps(AiLanguage.FR, List.of("get_budgets_status"))).isNotEmpty();
        assertThat(resolver.localizedFollowUps(AiLanguage.AR_DERJA_ARABIZI, List.of())).isNotEmpty();
    }
}
