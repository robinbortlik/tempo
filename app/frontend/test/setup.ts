import "@testing-library/jest-dom";

// Mock window.matchMedia for components that use it
Object.defineProperty(window, "matchMedia", {
  writable: true,
  value: (query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: () => {},
    removeListener: () => {},
    addEventListener: () => {},
    removeEventListener: () => {},
    dispatchEvent: () => false,
  }),
});

// Mock ResizeObserver
(
  globalThis as typeof globalThis & { ResizeObserver: typeof ResizeObserver }
).ResizeObserver = class ResizeObserver {
  observe() {}
  unobserve() {}
  disconnect() {}
};
