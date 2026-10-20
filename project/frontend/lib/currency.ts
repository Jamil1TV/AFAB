/**
 * Centralized currency formatting utility for AFAB.
 * Formats financial amounts with the user's business currency (e.g. QAR, AED, SAR, USD, EUR, GBP).
 */
export function formatNumberWithStyle(
  amount: number | string | null | undefined,
  numberFormat?: string
): string {
  const numericAmount = typeof amount === "string" ? parseFloat(amount) || 0 : amount || 0;
  
  const format =
    numberFormat ||
    (typeof window !== "undefined" ? localStorage.getItem("afab_number_format") : null) ||
    "US";

  const isNegative = numericAmount < 0;
  const absVal = Math.abs(numericAmount);
  const fixedStr = absVal.toFixed(2);
  const [rawInt, dec] = fixedStr.split(".");

  let formattedInt = rawInt;

  switch (format) {
    case "EU":
      formattedInt = rawInt.replace(/\B(?=(\d{3})+(?!\d))/g, ".");
      return `${isNegative ? "-" : ""}${formattedInt},${dec}`;

    case "SI":
      formattedInt = rawInt.replace(/\B(?=(\d{3})+(?!\d))/g, " ");
      return `${isNegative ? "-" : ""}${formattedInt},${dec}`;

    case "DOT":
      formattedInt = rawInt.replace(/\B(?=(\d{3})+(?!\d))/g, ",");
      return `${isNegative ? "-" : ""}${formattedInt}·${dec}`;

    case "RAW":
      return `${isNegative ? "-" : ""}${rawInt}.${dec}`;

    case "US":
    default:
      formattedInt = rawInt.replace(/\B(?=(\d{3})+(?!\d))/g, ",");
      return `${isNegative ? "-" : ""}${formattedInt}.${dec}`;
  }
}

export function formatCurrency(
  amount: number | string | null | undefined,
  currencyCode: string = "USD",
  numberFormat?: string
): string {
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
    TND: "DT ",
    MAD: "MAD ",
    KWD: "KWD ",
    BHD: "BHD ",
    OMR: "OMR ",
    EGP: "EGP ",
    CHF: "CHF ",
    TRY: "₺",
  };

  const formattedNumber = formatNumberWithStyle(amount, numberFormat);

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
    TND: "DT ",
    MAD: "MAD ",
    KWD: "KWD ",
    BHD: "BHD ",
    OMR: "OMR ",
    EGP: "EGP ",
    CHF: "CHF ",
    TRY: "₺",
  };
  return symbolMap[code] || `${code} `;
}
