import { describe, it, expect, beforeEach } from "vitest";
import i18n, { supportedLocales, localeMapping } from "../i18n";

describe("i18n configuration", () => {
  beforeEach(async () => {
    // Reset to default language before each test
    await i18n.changeLanguage("en");
  });

  it("initializes with English as the default language", () => {
    expect(i18n.language).toBe("en");
    expect(i18n.options.fallbackLng).toContain("en");
  });

  it("returns translated strings via t function", () => {
    const t = i18n.t.bind(i18n);

    // Test navigation translations
    expect(t("nav.dashboard")).toBe("Dashboard");
    expect(t("nav.clients")).toBe("Clients");
    expect(t("nav.settings")).toBe("Settings");

    // Test common translations
    expect(t("common.save")).toBe("Save");
    expect(t("common.cancel")).toBe("Cancel");
  });

  it("switches locale correctly with changeLanguage", async () => {
    // Start with English
    expect(i18n.language).toBe("en");
    expect(i18n.t("nav.dashboard")).toBe("Dashboard");

    // Switch to Czech
    await i18n.changeLanguage("cs");
    expect(i18n.language).toBe("cs");
    expect(i18n.t("nav.dashboard")).toBe("Prehled");
    expect(i18n.t("nav.clients")).toBe("Klienti");

    // Switch back to English
    await i18n.changeLanguage("en");
    expect(i18n.language).toBe("en");
    expect(i18n.t("nav.dashboard")).toBe("Dashboard");
  });

  it("exports supported locales and locale mapping", () => {
    expect(supportedLocales).toContain("en");
    expect(supportedLocales).toContain("cs");
    expect(localeMapping.en).toBe("en-US");
    expect(localeMapping.cs).toBe("cs-CZ");
  });
});
