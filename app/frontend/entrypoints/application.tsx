import { createInertiaApp } from "@inertiajs/react";
import { createRoot } from "react-dom/client";
import Layout from "../components/Layout";
import "../styles/application.css";

// Import all page components eagerly
const pages = import.meta.glob("../pages/**/*.tsx", { eager: true });

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
    createRoot(el).render(<App {...props} />);
  },
});
