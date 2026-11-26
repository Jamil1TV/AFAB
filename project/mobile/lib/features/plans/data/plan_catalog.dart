import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

@immutable
class PlanFeatureItem {
  const PlanFeatureItem({
    required this.label,
    this.included = true,
    this.tooltip,
  });

  final String label;
  final bool included;
  final String? tooltip;
}

@immutable
class PlanTierDefinition {
  const PlanTierDefinition({
    required this.slug,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyMonthlyPrice,
    required this.editableBusinessLimit,
    required this.featuresHeader,
    required this.features,
    this.highlighted = false,
    this.isVip = false,
  });

  final String slug;
  final String name;
  final String subtitle;
  final String description;
  final Decimal monthlyPrice;
  final Decimal yearlyMonthlyPrice;
  final int editableBusinessLimit;
  final String featuresHeader;
  final List<PlanFeatureItem> features;
  final bool highlighted;
  final bool isVip;

  Decimal priceForInterval(String interval) =>
      interval == 'yearly' ? yearlyMonthlyPrice : monthlyPrice;
}

@immutable
class PlanComparisonRow {
  const PlanComparisonRow({
    required this.feature,
    required this.freeValue,
    required this.plusValue,
    required this.proValue,
    this.tooltip,
  });

  final String feature;
  final String freeValue;
  final String plusValue;
  final String proValue;
  final String? tooltip;
}

/// Static tier & 11-row feature comparison catalog mirroring Web `PlansScreen.tsx`.
abstract final class PlanCatalog {
  static List<PlanTierDefinition> tiers(bool isAr) {
    return [
      PlanTierDefinition(
        slug: 'free',
        name: 'Free',
        subtitle: isAr ? 'دفتر البداية' : 'Starter Ledger',
        description: isAr
            ? 'إدارة مالية أساسية للمشاريع الفردية.'
            : 'Essential bookkeeping for solo founders getting organized.',
        monthlyPrice: Decimal.zero,
        yearlyMonthlyPrice: Decimal.zero,
        editableBusinessLimit: 1,
        featuresHeader: isAr ? 'ما تتضمنه الخطة:' : "What's included:",
        features: [
          PlanFeatureItem(
            label: isAr
                ? '10,000 رمز · 20 استعلام AI / شهر'
                : '10,000 tokens · 20 AI queries / mo',
          ),
          PlanFeatureItem(
            label: isAr
                ? 'شركة واحدة نشطة (قابلة للتعديل)'
                : '1 Active (Unlocked) business workspace',
            tooltip: isAr
                ? 'تبقى الشركات الإضافية مقفلة بأمان في وضع القراءة فقط.'
                : 'Additional businesses stay safely stored in Read-Only mode.',
          ),
          PlanFeatureItem(
            label: isAr
                ? 'تقارير مالية أساسية و5 تصديرات / شهر'
                : 'Basic financial reports & 5 exports / mo',
          ),
          PlanFeatureItem(
            label: isAr
                ? 'محاكاة أسعار الصرف وتنبيهات محلية'
                : 'FX engine & local rate alerts',
          ),
          PlanFeatureItem(
            label: isAr
                ? 'فترة تجريبية مجانية 7 أيام'
                : '7-day Plus free trial exclusivity',
            included: false,
          ),
        ],
      ),
      PlanTierDefinition(
        slug: 'plus',
        name: 'Plus',
        subtitle: isAr ? 'الشركات النامية' : 'Growing Businesses',
        description: isAr
            ? 'أتمتة مالية كاملة وتقارير PDF/Excel و3 شركات نشطة.'
            : 'Full financial automation, PDF/Excel reports, and 3 unlocked workspaces.',
        monthlyPrice: Decimal.parse('9.99'),
        yearlyMonthlyPrice: Decimal.parse('7.99'),
        editableBusinessLimit: 3,
        highlighted: true,
        featuresHeader: isAr ? 'كل ما في Free، بالإضافة إلى:' : 'Everything in Free, plus:',
        features: [
          PlanFeatureItem(
            label: isAr
                ? '150,000 رمز · 300 استعلام AI / شهر'
                : '150,000 tokens · 300 AI queries / mo',
          ),
          PlanFeatureItem(
            label: isAr
                ? 'حتى 3 شركات نشطة (قابلة للتعديل)'
                : 'Up to 3 Active (Unlocked) businesses',
            tooltip: isAr
                ? 'يمكنك التبديل بين الشركات النشطة والمقفلة في أي وقت.'
                : 'Swap active vs vaulted workspaces anytime without losing data.',
          ),
          PlanFeatureItem(
            label: isAr
                ? 'تقارير متقدمة ومقارنة الفترات (50 تصدير / شهر)'
                : 'Advanced reports & comparisons (50 exports / mo)',
          ),
          PlanFeatureItem(
            label: isAr
                ? 'مسودات إجراءات Copilot (معاملات، فواتير، ميزانيات)'
                : 'Copilot action drafts (transactions, invoices, budgets)',
          ),
          PlanFeatureItem(
            label: isAr
                ? 'تجربة مجانية 7 أيام لمستخدمي Plus الجدد'
                : '7-day free trial on first subscription',
          ),
        ],
      ),
      PlanTierDefinition(
        slug: 'pro',
        name: 'Pro',
        subtitle: isAr ? 'منظومة المدير المالي المتعددة' : 'Multi-Entity CFO Suite',
        description: isAr
            ? 'أقصى سعة مع 5 شركات نشطة وتصدير غير محدود وتقارير مخصصة.'
            : 'Maximum scale with 5 active businesses, unlimited exports, and custom reporting.',
        monthlyPrice: Decimal.parse('19.99'),
        yearlyMonthlyPrice: Decimal.parse('15.99'),
        editableBusinessLimit: 5,
        isVip: true,
        featuresHeader: isAr ? 'كل ما في Plus، بالإضافة إلى:' : 'Everything in Plus, plus:',
        features: [
          PlanFeatureItem(
            label: isAr
                ? 'رموز واستعلامات AI غير محدودة'
                : 'Unlimited AI Copilot tokens & queries',
          ),
          PlanFeatureItem(
            label: isAr
                ? 'حتى 5 شركات نشطة (قابلة للتعديل)'
                : 'Up to 5 Active (Unlocked) businesses',
          ),
          PlanFeatureItem(
            label: isAr
                ? 'تقارير مخصصة النطاق وتصدير غير محدود'
                : 'Custom date-range reports & unlimited exports',
          ),
          PlanFeatureItem(
            label: isAr
                ? 'أولوية الدعم الفني والمتابعة'
                : 'Priority support & CFO SLA',
          ),
        ],
      ),
    ];
  }

  static List<PlanComparisonRow> comparisonRows(bool isAr) {
    return [
      PlanComparisonRow(
        feature: isAr ? 'رموز واستعلامات AI Copilot' : 'AI Copilot Tokens & Queries',
        freeValue: isAr ? '10K · 20 استعلام' : '10K · 20 queries',
        plusValue: isAr ? '150K · 300 استعلام' : '150K · 300 queries',
        proValue: isAr ? 'غير محدود' : 'Unlimited',
      ),
      PlanComparisonRow(
        feature: isAr ? 'توصيات الذكاء الاصطناعي' : 'AI Recommendations',
        freeValue: isAr ? 'أساسية' : 'Basic',
        plusValue: isAr ? 'مشمول' : 'Included',
        proValue: isAr ? 'أولوية' : 'Priority',
      ),
      PlanComparisonRow(
        feature: isAr ? 'التنبؤ بالتدفق النقدي' : 'Cash Flow Forecasting',
        freeValue: isAr ? 'أساسي' : 'Basic',
        plusValue: isAr ? 'متقدم' : 'Advanced',
        proValue: isAr ? 'كامل + محاكاة' : 'Full + Simulations',
      ),
      PlanComparisonRow(
        feature: isAr ? 'التقارير المالية' : 'Financial Reports',
        freeValue: isAr ? 'أساسي' : 'Basic',
        plusValue: isAr ? 'متقدم' : 'Advanced',
        proValue: isAr ? 'مخصص' : 'Custom Range',
      ),
      PlanComparisonRow(
        feature: isAr ? 'الفواتير' : 'Invoices',
        freeValue: isAr ? 'مشمول' : 'Included',
        plusValue: isAr ? 'مشمول' : 'Included',
        proValue: isAr ? 'غير محدود' : 'Unlimited',
      ),
      PlanComparisonRow(
        feature: isAr ? 'الشركات النشطة (المفتوحة)' : 'Active (Unlocked) Businesses',
        freeValue: '1',
        plusValue: '3',
        proValue: '5',
        tooltip: isAr
            ? 'الحد الأقصى للشركات القابلة للتعديل في نفس الوقت.'
            : 'Maximum simultaneously editable workspaces.',
      ),
      PlanComparisonRow(
        feature: isAr ? 'الشركات المقفلة المحفوظة' : 'Locked Vaulted Businesses',
        freeValue: isAr ? 'غير محدود (قراءة فقط)' : 'Unlimited (Read-Only)',
        plusValue: isAr ? 'غير محدود (قراءة فقط)' : 'Unlimited (Read-Only)',
        proValue: isAr ? 'غير محدود (قراءة فقط)' : 'Unlimited (Read-Only)',
      ),
      PlanComparisonRow(
        feature: isAr ? 'تصدير البيانات' : 'Export Data',
        freeValue: isAr ? '5 / شهر' : '5 / mo',
        plusValue: isAr ? '50 / شهر' : '50 / mo',
        proValue: isAr ? 'غير محدود' : 'Unlimited',
      ),
      PlanComparisonRow(
        feature: isAr ? 'الدعم عبر البريد' : 'Email Support',
        freeValue: isAr ? 'قياسي' : 'Standard',
        plusValue: isAr ? 'مشمول' : 'Included',
        proValue: isAr ? 'مشمول' : 'Included',
      ),
      PlanComparisonRow(
        feature: isAr ? 'دعم بأولوية' : 'Priority Support',
        freeValue: '—',
        plusValue: isAr ? 'عبر البريد' : 'Email priority',
        proValue: isAr ? 'أولوية قصوى' : 'Dedicated VIP',
      ),
      PlanComparisonRow(
        feature: isAr ? 'تجربة 7 أيام مجاناً (Plus فقط)' : '7-Day Free Trial (Plus Exclusive)',
        freeValue: '—',
        plusValue: isAr ? 'مشمول' : 'Included',
        proValue: '—',
      ),
    ];
  }
}
