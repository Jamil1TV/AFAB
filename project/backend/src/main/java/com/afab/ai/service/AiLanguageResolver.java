package com.afab.ai.service;

import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Polyglot Continuity Engine supporting English, French, Modern Standard Arabic,
 * Tunisian Derja (Arabic script), and Tunisian Derja (Arabizi / Latin script).
 */
@Service
public class AiLanguageResolver {

    public enum AiLanguage {
        EN,
        FR,
        AR_MSA,
        AR_DERJA_SCRIPT,
        AR_DERJA_ARABIZI;

        public static AiLanguage fromCode(String raw) {
            if (raw == null || raw.isBlank()) return EN;
            try {
                return AiLanguage.valueOf(raw.trim().toUpperCase(Locale.ROOT));
            } catch (IllegalArgumentException e) {
                return EN;
            }
        }
    }

    private static final Pattern ARABIC_CHAR_PATTERN = Pattern.compile("[\\u0600-\\u06FF]");
    private static final Pattern ARABIZI_DIGIT_WORD_PATTERN = Pattern.compile("\\b[a-zA-Z]*[a-zA-Z][35789][a-zA-Z0-9]*\\b|\\b[35789][a-zA-Z]{2,}\\b");

    private static final Set<String> DERJA_ARABIC_MARKERS = Set.of(
            "قداش", "شنوة", "شني", "شنية", "توة", "توا", "برشا", "موش", "مش", "علاش",
            "البارح", "لبارح", "نجم", "تنجم", "فلوس", "فلوسي", "متاع", "متاعي", "ياخي",
            "باهي", "يزي", "بقداش", "صرف", "صرفت", "خلصت", "نحب", "تحب", "وين", "وقتاش",
            "عندي", "عندك", "فما", "لازم", "عسلامة", "يعيشك", "بالتونسي", "تونسي", "الدارجة",
            "أمان", "شكون", "كيفاش", "زعما", "هاو", "هذاكا", "هاكم"
    );

    private static final Set<String> ARABIZI_LEXICON = Set.of(
            "kadeh", "qadeh", "chneya", "chniya", "cheniya", "flous", "flousi", "lbereh", "lbara7",
            "khalast", "5alast", "tnajim", "tnajem", "tehki", "ta7ki", "jewebni", "jawebni", "behi",
            "barcha", "najjem", "najem", "aawenni", "3awenni", "win", "waqtech", "wa9tech", "chrit",
            "sraft", "chhar", "masarif", "mte3", "mta3", "mta3i", "mte3i", "aslema", "3aslema",
            "aaychek", "3aychek", "nheb", "n7eb", "t7eb", "theb", "fama", "fammech", "mouch", "moch",
            "tounsi", "derja", "aalech", "3lech", "kifech", "chkoun", "faktur", "fatoura", "yesser",
            "ama", "hal", "khater", "5ater", "tawa", "toua", "chwaya", "yezzy"
    );

    private static final Set<String> FRENCH_MARKERS = Set.of(
            "bonjour", "bonsoir", "salut", "merci", "combien", "depense", "depenses", "dépense",
            "dépenses", "facture", "factures", "mois", "client", "clients", "revenu", "revenus",
            "benefice", "bénéfice", "pourquoi", "montre", "resume", "résumé", "oui", "non",
            "hier", "demain", "payer", "paye", "payé", "tresorerie", "trésorerie", "entreprise",
            "quelles", "quels", "quelle", "quel", "sont", "mes", "mon", "ma", "avec", "pour",
            "dans", "cette", "ce", "derniere", "dernier", "retard", "impayee", "impayée",
            "francais", "français", "analyser", "analyse", "rapport", "prevision", "prévision",
            "embaucher", "depuis", "semaine", "annee", "année", "recu", "reçu"
    );

    private static final Set<String> ENGLISH_MARKERS = Set.of(
            "how", "what", "when", "where", "why", "which", "who", "show", "give", "tell",
            "expense", "expenses", "spend", "spent", "revenue", "income", "profit", "margin",
            "invoice", "invoices", "overdue", "unpaid", "paid", "customer", "customers",
            "budget", "budgets", "this", "last", "month", "week", "quarter", "year",
            "create", "add", "draft", "analyze", "analyse", "receipt", "file", "summary",
            "forecast", "cashflow", "runway", "hire", "please", "explain", "compare",
            "english", "hello", "thanks", "thank", "yes", "sure", "okay"
    );

    public AiLanguage resolveLanguage(String userMessage, AiLanguage previousActiveLanguage, String uiLocale) {
        String text = userMessage != null ? userMessage.trim() : "";
        String lower = text.toLowerCase(Locale.ROOT);

        // 1. Explicit language switch directives take highest priority
        AiLanguage explicit = detectExplicitSwitch(lower, text);
        if (explicit != null) {
            return explicit;
        }

        if (text.isEmpty()) {
            return inheritOrFallback(previousActiveLanguage, uiLocale);
        }

        // 2. Arabic script ratio check (>= 30% of letters)
        int arabicChars = 0;
        int latinChars = 0;
        for (int i = 0; i < text.length(); i++) {
            char ch = text.charAt(i);
            if (ch >= '\u0600' && ch <= '\u06FF') {
                arabicChars++;
            } else if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')
                    || "éèêàçùôîûëïœÉÈÊÀÇÙÔÎÛËÏŒ".indexOf(ch) >= 0) {
                latinChars++;
            }
        }

        int totalLetters = arabicChars + latinChars;
        if (arabicChars > 0 && totalLetters > 0 && ((double) arabicChars / totalLetters) >= 0.30) {
            for (String marker : DERJA_ARABIC_MARKERS) {
                if (text.contains(marker)) {
                    return AiLanguage.AR_DERJA_SCRIPT;
                }
            }
            return AiLanguage.AR_MSA;
        }

        // 3. Latin script scoring: Tunisian Arabizi vs French vs English
        int arabiziScore = scoreArabizi(lower);
        int frenchScore = scoreFrench(lower);
        int englishScore = scoreEnglish(lower);

        if (arabiziScore > 0 && arabiziScore >= frenchScore && arabiziScore >= englishScore) {
            return AiLanguage.AR_DERJA_ARABIZI;
        }
        if (frenchScore > 0 && frenchScore > englishScore && frenchScore > arabiziScore) {
            return AiLanguage.FR;
        }
        if (englishScore > 0 && englishScore > frenchScore && englishScore > arabiziScore) {
            return AiLanguage.EN;
        }
        if (frenchScore > 0 && frenchScore == englishScore) {
            // Tie-break between FR and EN toward previous conversation language if it's one of them
            if (previousActiveLanguage == AiLanguage.FR || previousActiveLanguage == AiLanguage.EN) {
                return previousActiveLanguage;
            }
            return "fr".equalsIgnoreCase(uiLocale) ? AiLanguage.FR : AiLanguage.EN;
        }

        // 4. Short/ambiguous turns ("ok", "1200", "Acme", "?") inherit sticky conversation language
        return inheritOrFallback(previousActiveLanguage, uiLocale);
    }

    private AiLanguage detectExplicitSwitch(String lower, String raw) {
        if (containsAny(lower, "in english", "en anglais", "speak english", "reply in english", "answer in english")
                || raw.contains("بالانجليزية") || raw.contains("بالإنجليزية") || raw.contains("بالإنجليزي")) {
            return AiLanguage.EN;
        }
        if (containsAny(lower, "en francais", "en français", "in french", "speak french", "parle francais", "parle français", "b francais", "bil francais")
                || raw.contains("بالفرنسية") || raw.contains("بالفرونسي")) {
            return AiLanguage.FR;
        }
        if (containsAny(lower, "b tounsi", "bel tounsi", "bettounsi", "in derja", "in tunisian", "tehki tounsi", "ehki tounsi", "jewebni b tounsi", "jawebni b tounsi")) {
            return AiLanguage.AR_DERJA_ARABIZI;
        }
        if (raw.contains("بالتونسي") || raw.contains("بالدارجة") || raw.contains("جاوبني بالتونسي")) {
            return AiLanguage.AR_DERJA_SCRIPT;
        }
        if (containsAny(lower, "in arabic", "en arabe", "speak arabic")
                || raw.contains("بالعربية") || raw.contains("بالفصحى")) {
            return AiLanguage.AR_MSA;
        }
        return null;
    }

    private int scoreArabizi(String lower) {
        int score = 0;
        Matcher m = ARABIZI_DIGIT_WORD_PATTERN.matcher(lower);
        while (m.find()) {
            score += 2;
        }
        String[] tokens = tokenizeLatin(lower);
        for (String token : tokens) {
            if (ARABIZI_LEXICON.contains(token)) {
                score += 2;
            }
        }
        return score;
    }

    private int scoreFrench(String lower) {
        int score = 0;
        for (int i = 0; i < lower.length(); i++) {
            char ch = lower.charAt(i);
            if ("éèêàçùôîûëïœ".indexOf(ch) >= 0) {
                score += 2;
                break;
            }
        }
        for (String token : tokenizeLatin(lower)) {
            if (FRENCH_MARKERS.contains(token)) {
                score += 2;
            }
        }
        return score;
    }

    private int scoreEnglish(String lower) {
        int score = 0;
        for (String token : tokenizeLatin(lower)) {
            if (ENGLISH_MARKERS.contains(token)) {
                score += 2;
            }
        }
        return score;
    }

    private AiLanguage inheritOrFallback(AiLanguage previousActiveLanguage, String uiLocale) {
        if (previousActiveLanguage != null) {
            return previousActiveLanguage;
        }
        if ("ar".equalsIgnoreCase(uiLocale)) {
            return AiLanguage.AR_MSA;
        }
        if ("fr".equalsIgnoreCase(uiLocale)) {
            return AiLanguage.FR;
        }
        return AiLanguage.EN;
    }

    public String buildLanguageContract(AiLanguage lang) {
        return switch (lang) {
            case FR -> """
                    TARGET LANGUAGE LOCK: FRENCH (FR).
                    You MUST write your ENTIRE response in clear, professional business French (français).
                    NEVER reply in English or add meta-commentary about switching languages.
                    Keep all currency codes, invoice numbers, and Markdown tables exact.""";
            case AR_MSA -> """
                    TARGET LANGUAGE LOCK: MODERN STANDARD ARABIC (AR_MSA).
                    You MUST write your ENTIRE response in clear, professional Modern Standard Arabic (العربية الفصحى).
                    NEVER switch to English prose or write meta explanations about language capability.
                    Keep numeric figures, currency ISO codes, and Markdown formatting crystal clear.""";
            case AR_DERJA_SCRIPT -> """
                    TARGET LANGUAGE LOCK: TUNISIAN DERJA IN ARABIC SCRIPT (AR_DERJA_SCRIPT).
                    You MUST reply directly in natural, fluent Tunisian Derja written in Arabic script (الدارجة التونسية بالحروف العربية).
                    Keep financial numbers, dates, and currency codes accurate. NEVER reply in English or say you will switch languages—just speak Tunisian directly.""";
            case AR_DERJA_ARABIZI -> """
                    TARGET LANGUAGE LOCK: TUNISIAN DERJA IN LATIN/ARABIZI SCRIPT (AR_DERJA_ARABIZI).
                    You MUST reply directly in natural, fluent Tunisian Derja using Latin/Arabizi script (e.g. "Ey akid! Hani chofet les chiffres mte3ek...").
                    NEVER reply in English or refuse or write a meta-message about speaking Tunisian—answer the business question directly in Tunisian Arabizi.""";
            case EN -> """
                    TARGET LANGUAGE LOCK: ENGLISH (EN).
                    You MUST write your ENTIRE response in crisp, executive English.
                    Ignore any earlier French/Arabic turns when the user has switched to English.""";
        };
    }

    /**
     * Guards against cases where the model slips into English boilerplate (e.g. "I can communicate in...")
     * when the active target language is French, Arabic, or Tunisian Derja.
     */
    public boolean needsLanguageRepair(AiLanguage target, String modelOutput) {
        if (target == null || target == AiLanguage.EN || modelOutput == null || modelOutput.isBlank()) {
            return false;
        }
        String lower = modelOutput.toLowerCase(Locale.ROOT);
        if (lower.contains("i can communicate in")
                || lower.contains("i can speak in")
                || lower.contains("how can i help you today")
                || lower.contains("here is a summary of your")) {
            return true;
        }

        if (target == AiLanguage.AR_MSA || target == AiLanguage.AR_DERJA_SCRIPT) {
            int arCount = 0;
            Matcher m = ARABIC_CHAR_PATTERN.matcher(modelOutput);
            while (m.find()) {
                arCount++;
            }
            return arCount < 8 && modelOutput.length() > 25;
        }

        if (target == AiLanguage.FR) {
            int frScore = scoreFrench(lower);
            int enScore = scoreEnglish(lower);
            return enScore >= 6 && frScore == 0;
        }

        if (target == AiLanguage.AR_DERJA_ARABIZI) {
            int dzScore = scoreArabizi(lower);
            int enScore = scoreEnglish(lower);
            return enScore >= 6 && dzScore == 0;
        }

        return false;
    }

    public String buildRepairSystemPrompt(AiLanguage target) {
        return """
                Rewrite the following financial response so that 100%% of the prose strictly follows this target language contract:
                %s
                CRITICAL: Preserve every single number, currency code, invoice number, category name, date, and Markdown table/bullet untouched. Do NOT invent or change any figure. Output ONLY the translated/rewritten response."""
                .formatted(buildLanguageContract(target));
    }

    public List<String> localizedFollowUps(AiLanguage lang, List<String> toolsUsed) {
        List<String> tools = toolsUsed != null ? toolsUsed : List.of();
        boolean budget = tools.contains("get_budgets_status");
        boolean invoice = tools.contains("get_invoices_overview");
        boolean forecast = tools.contains("simulate_cashflow_forecast");
        boolean pulse = tools.contains("get_financial_pulse");

        return switch (lang) {
            case FR -> {
                if (budget) yield List.of("Quelles dépenses expliquent ce dépassement ?", "Y a-t-il des factures en retard ce mois-ci ?");
                if (invoice) yield List.of("Rédige une relance pour la facture la plus en retard", "Qui sont mes meilleurs clients par revenus ?");
                if (forecast) yield List.of("Que se passe-t-il si mon meilleur client paie avec 30 jours de retard ?", "Résumé du P&L de ce mois-ci");
                if (pulse) yield List.of("Affiche les dépenses sans reçu", "Compare ce mois au mois dernier");
                yield List.of("Quelles factures sont en retard ?", "Vérifie la santé de mes budgets", "Simule ma trésorerie sur 6 mois");
            }
            case AR_MSA -> {
                if (budget) yield List.of("ما هي المصروفات التي رفعت هذا الإنفاق؟", "هل توجد فواتير متأخرة حالياً؟");
                if (invoice) yield List.of("أعدّ تذكير دفع لأكثر فاتورة متأخرة", "من هم أعلى العملاء إيراداً؟");
                if (forecast) yield List.of("ماذا يحدث لو تأخر أكبر عميل 30 يوماً؟", "أعطني ملخص الأرباح والخسائر لهذا الشهر");
                if (pulse) yield List.of("أظهر المصروفات التي ينقصها إيصال", "قارن هذا الشهر بالشهر الماضي");
                yield List.of("ما هي الفواتير المتأخرة حالياً؟", "هل اقتربت أياً من الميزانيات من حدها؟", "توقع التدفق النقدي لـ 6 أشهر");
            }
            case AR_DERJA_SCRIPT -> {
                if (budget) yield List.of("شنوة المصاريف اللي زادت برشا هذا الشهر؟", "فما فواتير متأخرة توة؟");
                if (invoice) yield List.of("حضّرلي ميساج تذكير لأكثر فاتورة متأخرة", "شكون أكثر كليانات دخّلو فلوس؟");
                if (forecast) yield List.of("شنوة يصير كان أكبر كليان يبطى 30 يوم في الخلاص؟", "وريني ملخص المداخيل والمصاريف متاع الشهر هذا");
                yield List.of("شنية الفواتير اللي مازالت ما تخلصتش؟", "قداش صرفت هذا الشهر مقارنة بالشهر اللي فات؟", "اعملي محاكاة للفلوس في 6 شهور الجايين");
            }
            case AR_DERJA_ARABIZI -> {
                if (budget) yield List.of("Chniya l'masarif elli zedet barcha hal chhar?", "Fama fatourat met2a5ra tawa?");
                if (invoice) yield List.of("7adharli message tadhkir l'akther fatoura met2a5ra", "Chkoun akther clients da5lou flous?");
                if (forecast) yield List.of("Chnowa ysir ken akbar client yebta 30 youm?", "Aatini molakhas hal chhar");
                yield List.of("Chniya l'fatourat elli met2a5ra tawa?", "Kadeh sraft hal chhar w chniya akther masarif?", "Aamelli forecast l'flous 6 chhour ljeyin");
            }
            case EN -> {
                if (budget) yield List.of("Which transactions drove this spending?", "Do I have any overdue invoices?");
                if (invoice) yield List.of("Draft a payment reminder for my top overdue invoice", "Who are my top customers by revenue?");
                if (forecast) yield List.of("What happens if my top client pays 30 days late?", "Show my monthly P&L summary");
                if (pulse) yield List.of("Show expenses missing receipts", "Compare this month against last month");
                yield List.of("Which invoices are overdue?", "Am I approaching any budget limits?", "Simulate my 6-month cashflow");
            }
        };
    }

    private String[] tokenizeLatin(String lower) {
        return lower.replaceAll("[^a-z0-9éèêàçùôîûëïœ]", " ").trim().split("\\s+");
    }

    private boolean containsAny(String haystack, String... needles) {
        for (String n : needles) {
            if (haystack.contains(n)) return true;
        }
        return false;
    }
}
