/**
 * Centralized currency formatting utility for AFAB.
 * Formats financial amounts with the user's business currency (e.g. QAR, AED, SAR, USD, EUR, GBP).
 */
export function formatCurrency(amount: number | string | null | undefined, currencyCode: string = "USD"): string {
  const numericAmount = typeof amount === "string" ? parseFloat(amount) || 0 : amount || 0;
  const code = (currencyCode || "USD").toUpperCase().trim();

  // Known currency symbols and prefixes
  const symbolMap: Record<string, string> = {
    USD: "$",
    EUR: "€",
    GBP: "£",
    JPY: "¥",
    CAD: "CA$",
    AUD: "A$",
    QAR: "QAR ",
    AED: "AED ",
    SAR: "SAR ",
    KWD: "KWD ",
    BHD: "BHD ",
    OMR: "OMR ",
    EGP: "EGP ",
  };

  const formattedNumber = numericAmount.toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });

  const symbol = symbolMap[code];
  if (symbol) {
    return `${symbol}${formattedNumber}`;
  }

  return `${code} ${formattedNumber}`;
}

export function getCurrencySymbol(currencyCode: string = "USD"): string {
  const code = (currencyCode || "USD").toUpperCase().trim();
  const symbolMap: Record<string, string> = {
    USD: "$",
    EUR: "€",
    GBP: "£",
    JPY: "¥",
    QAR: "QAR ",
    AED: "AED ",
    SAR: "SAR ",
    KWD: "KWD ",
    BHD: "BHD ",
    OMR: "OMR ",
    EGP: "EGP ",
  };
  return symbolMap[code] || `${code} `;
}
