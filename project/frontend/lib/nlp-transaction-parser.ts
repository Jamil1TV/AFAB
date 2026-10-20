import { CategoryItem } from "./api/transactions";

export interface ParsedTransaction {
  type: "INCOME" | "EXPENSE";
  amount: number | null;
  rawAmount: string;
  description: string;
  transactionDate: string;
  paymentMethod: string;
  categoryId?: string;
  categoryName?: string;
  categoryColor?: string;
  taxDeductible?: boolean;
  confidence: number; // 0 to 1
}

export function parseNaturalLanguageTransaction(
  input: string,
  categories: CategoryItem[] = []
): ParsedTransaction {
  const text = input.trim();
  if (!text) {
    return {
      type: "EXPENSE",
      amount: null,
      rawAmount: "",
      description: "",
      transactionDate: new Date().toISOString().split("T")[0],
      paymentMethod: "CARD",
      confidence: 0,
    };
  }

  let confidence = 0.2;
  const lower = text.toLowerCase();

  // 1. Detect Type (Income vs Expense)
  const incomeKeywords = [
    "received", "earned", "income", "invoiced", "deposit", 
    "sold", "revenue", "got paid", "salary", "refund from", "client"
  ];
  const isIncome = incomeKeywords.some((kw) => lower.includes(kw));
  const type: "INCOME" | "EXPENSE" = isIncome ? "INCOME" : "EXPENSE";
  if (isIncome) confidence += 0.2;

  // 2. Extract Amount
  // Matches: $450, 450$, 450.50, 450 usd, 450 dollars, 450.00
  let amount: number | null = null;
  let rawAmount = "";
  const amountRegex = /(?:[$€£¥]\s*)?(\b\d+(?:[.,]\d{1,2})?\b)(?:\s*(?:[$€£¥]|usd|eur|gbp|tnd|kwd|dollars|bucks|dh|mad))?/i;
  const amountMatch = text.match(amountRegex);

  if (amountMatch && amountMatch[1]) {
    const cleaned = amountMatch[1].replace(",", ".");
    const parsedNum = parseFloat(cleaned);
    if (!isNaN(parsedNum) && parsedNum > 0) {
      amount = parsedNum;
      rawAmount = amountMatch[0].trim();
      confidence += 0.3;
    }
  }

  // 3. Extract Date
  let transactionDate = new Date().toISOString().split("T")[0];
  const today = new Date();
  if (lower.includes("yesterday")) {
    const d = new Date(today);
    d.setDate(d.getDate() - 1);
    transactionDate = d.toISOString().split("T")[0];
    confidence += 0.15;
  } else {
    // Check YYYY-MM-DD
    const isoDateMatch = text.match(/\b(20\d{2}-\d{2}-\d{2})\b/);
    if (isoDateMatch) {
      transactionDate = isoDateMatch[1];
      confidence += 0.2;
    }
  }

  // 4. Extract Payment Method
  let paymentMethod = "CARD";
  if (/\b(cash|bills)\b/i.test(lower)) {
    paymentMethod = "CASH";
    confidence += 0.1;
  } else if (/\b(bank|wire|transfer|ach|direct deposit)\b/i.test(lower)) {
    paymentMethod = "BANK_TRANSFER";
    confidence += 0.1;
  } else if (/\b(paypal|stripe|crypto)\b/i.test(lower)) {
    paymentMethod = "OTHER";
    confidence += 0.1;
  } else if (/\b(card|credit card|debit|visa|mastercard|amex)\b/i.test(lower)) {
    paymentMethod = "CARD";
    confidence += 0.1;
  }

  // 5. Detect Tax Deductible
  const isTaxDeductible = /\b(tax deductible|deductible|write off|business expense|vat)\b/i.test(lower);

  // 6. Match Category
  let categoryId: string | undefined;
  let categoryName: string | undefined;
  let categoryColor: string | undefined;

  const filteredCategories = categories.filter(
    (c) => c.type.toUpperCase() === type
  );

  // First exact/fuzzy match on category names
  for (const cat of filteredCategories) {
    const catLower = cat.name.toLowerCase();
    if (lower.includes(catLower)) {
      categoryId = cat.id;
      categoryName = cat.name;
      categoryColor = cat.color;
      confidence += 0.2;
      break;
    }
  }

  // Fallback keyword rules if not directly matched by name
  if (!categoryId && filteredCategories.length > 0) {
    const keywordMap: Record<string, string[]> = {
      "Hosting": ["aws", "cloud", "server", "digitalocean", "vercel", "hosting", "azure"],
      "Software": ["figma", "github", "slack", "zoom", "adobe", "google", "notion", "linear", "jira", "subscription"],
      "Office Supplies": ["office", "desk", "paper", "stationery", "staples", "chair"],
      "Meals & Entertainment": ["lunch", "dinner", "food", "restaurant", "coffee", "starbucks", "drinks", "team meal"],
      "Marketing": ["ads", "facebook", "meta", "google ads", "marketing", "promo", "twitter", "linkedin"],
      "Sales": ["client", "customer", "project", "consulting", "service"],
    };

    for (const [targetCat, keywords] of Object.entries(keywordMap)) {
      if (keywords.some((kw) => lower.includes(kw))) {
        const found = filteredCategories.find(
          (c) => c.name.toLowerCase().includes(targetCat.toLowerCase())
        );
        if (found) {
          categoryId = found.id;
          categoryName = found.name;
          categoryColor = found.color;
          confidence += 0.15;
          break;
        }
      }
    }
  }

  // 7. Clean Description / Merchant
  // Remove matched amount, dates, and noise syntax
  let cleanDesc = text;
  if (rawAmount) {
    cleanDesc = cleanDesc.replace(rawAmount, "");
  }
  const noiseRegex = /\b(paid|spent|bought|cost|for|to|via|on|with|yesterday|today|in cash|by card|credit card|bank transfer|tax deductible|write off)\b/gi;
  cleanDesc = cleanDesc.replace(noiseRegex, " ").replace(/\s+/g, " ").trim();

  // Remove leading/trailing prepositions or punctuation
  cleanDesc = cleanDesc.replace(/^[\s,.\-–:]+|[\s,.\-–:]+$/g, "");

  const description = cleanDesc.length > 0
    ? cleanDesc.charAt(0).toUpperCase() + cleanDesc.slice(1)
    : (type === "INCOME" ? "Client Payment" : "Expense Payment");

  return {
    type,
    amount,
    rawAmount,
    description,
    transactionDate,
    paymentMethod,
    categoryId,
    categoryName,
    categoryColor,
    taxDeductible: isTaxDeductible,
    confidence: Math.min(1.0, Math.round(confidence * 100) / 100),
  };
}
