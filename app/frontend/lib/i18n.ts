import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import en from "@/locales/en.json";
import cs from "@/locales/cs.json";

export const supportedLocales = ["en", "cs"] as const;
export type SupportedLocale = (typeof supportedLocales)[number];

// Locale mapping for number/currency formatting
export const localeMapping: Record<SupportedLocale, string> = {
  en: "en-US",
  cs: "cs-CZ",
};

i18n.use(initReactI18next).init({
  resources: {
    en: { translation: en },
    cs: { translation: cs },
  },
  lng: "en",
  fallbackLng: "en",
  interpolation: {
    escapeValue: false,
  },
});

export default i18n;
