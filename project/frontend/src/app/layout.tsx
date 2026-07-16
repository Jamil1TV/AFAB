import type { Metadata } from "next";
import { cookies } from "next/headers";
import { Inter } from "next/font/google";
import { ThemeProvider } from "@/providers/theme-provider";
import { getDirection, isSupportedLocale } from "@/lib/rtl";
import "./globals.css";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "AFAB",
  description: "AI Finance Assistant for Business",
};

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const cookieStore = await cookies();
  const localeFromCookie = cookieStore.get("AFAB_LOCALE")?.value;
  const locale = isSupportedLocale(localeFromCookie) ? localeFromCookie : "en";
  const direction = getDirection(locale);

  return (
    <html
      lang={locale}
      dir={direction}
      className={`${inter.variable} h-full antialiased`}
      suppressHydrationWarning
    >
      <body className="min-h-full flex flex-col">
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  );
}
