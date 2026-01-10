import { createInertiaApp } from "@inertiajs/react";
import { createRoot } from "react-dom/client";
import Layout from "../components/Layout";
import "../styles/application.css";
import i18n from "@/lib/i18n";

// Register service worker for PWA support
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker
      .register("/service-worker.js")
      .then((registration) => {
        console.log("ServiceWorker registered:", registration.scope);
      })
      .catch((error) => {
        console.log("ServiceWorker registration failed:", error);
      });
  });
}

// Import all page components eagerly (excluding test files)
const pages = import.meta.glob(
  ["../pages/**/*.tsx", "!../pages/**/__tests__/**", "!../pages/**/*.test.tsx"],
  { eager: true }
);

createInertiaApp({
  resolve: (name) => {
    const page = pages[`../pages/${name}.tsx`] as {
      default: React.ComponentType & {
        layout?: (page: React.ReactNode) => React.ReactNode;
      };
    };
    if (!page) {
      throw new Error(`Page not found: ${name}`);
    }
    // Set default layout if page doesn't define its own
    const pageComponent = page.default;
    if (!pageComponent.layout) {
      pageComponent.layout = (page) => <Layout>{page}</Layout>;
    }
    return page;
  },
  setup({ el, App, props }) {
    // Initialize i18n with locale from Inertia props
    const locale = (props.initialPage.props.locale as string) || "en";
    i18n.changeLanguage(locale);

    createRoot(el).render(<App {...props} />);
  },
});
