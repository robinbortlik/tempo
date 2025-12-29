import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import { resolve } from "path";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: ["./app/frontend/test/setup.ts"],
    include: ["app/frontend/**/*.{test,spec}.{ts,tsx}"],
    coverage: {
      provider: "v8",
      reporter: ["text", "json", "html"],
      include: ["app/frontend/**/*.{ts,tsx}"],
      exclude: [
        "app/frontend/**/*.{test,spec}.{ts,tsx}",
        "app/frontend/test/**/*",
        "app/frontend/vite-env.d.ts",
      ],
    },
  },
  resolve: {
    alias: {
      "@": resolve(__dirname, "app/frontend"),
    },
  },
});
