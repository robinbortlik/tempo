import { useTranslation } from "react-i18next";
import { Button } from "@/components/ui/button";

export default function Home() {
  const { t } = useTranslation();

  return (
    <div className="min-h-screen bg-stone-50 flex items-center justify-center p-4">
      <div className="text-center">
        <div className="inline-flex items-center justify-center w-16 h-16 bg-stone-900 rounded-xl mb-6">
          <svg
            className="w-8 h-8 text-white"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
        </div>
        <h1 className="text-3xl font-semibold text-stone-900 mb-2">Tempo</h1>
        <p className="text-stone-500 mb-6">{t("pages.home.welcome")}</p>
        <div className="flex items-center justify-center gap-3">
          <Button variant="default">{t("pages.home.getStarted")}</Button>
          <Button variant="outline">{t("pages.home.learnMore")}</Button>
        </div>
      </div>
    </div>
  );
}
