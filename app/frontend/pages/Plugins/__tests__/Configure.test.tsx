import { render, screen } from "@testing-library/react";
import { describe, it, expect, vi } from "vitest";

// Mock Inertia
vi.mock("@inertiajs/react", () => ({
  Head: ({ title }: { title: string }) => <title>{title}</title>,
  usePage: () => ({
    props: {
      plugin: {
        plugin_name: "example",
        plugin_version: "1.0.0",
        plugin_description: "Example plugin",
        enabled: true,
        configured: false,
      },
      credentials: {},
      settings: {},
      credential_fields: [
        { name: "api_key", label: "API Key", type: "password", required: true },
      ],
      setting_fields: [
        {
          name: "import_limit",
          label: "Import limit",
          type: "number",
          required: false,
        },
      ],
      flash: {},
    },
  }),
  router: {
    patch: vi.fn(),
    delete: vi.fn(),
  },
  Link: ({ href, children }: { href: string; children: React.ReactNode }) => (
    <a href={href}>{children}</a>
  ),
}));

// Mock i18n
vi.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: (key: string, params?: Record<string, string>) => {
      if (key === "pages.plugins.configuration.title" && params?.name) {
        return `Configure ${params.name}`;
      }
      return key;
    },
  }),
}));

// Mock sonner
vi.mock("sonner", () => ({
  toast: { success: vi.fn(), error: vi.fn() },
  Toaster: () => null,
}));

// Mock the ui sonner component
vi.mock("@/components/ui/sonner", () => ({
  Toaster: () => null,
}));

// Import after mocks
import PluginsConfigure from "../Configure";

describe("PluginsConfigure", () => {
  it("renders plugin name and version", () => {
    render(<PluginsConfigure />);

    expect(screen.getByText("Configure example")).toBeInTheDocument();
    expect(screen.getByText("v1.0.0")).toBeInTheDocument();
  });

  it("renders plugin description", () => {
    render(<PluginsConfigure />);

    expect(screen.getByText("Example plugin")).toBeInTheDocument();
  });

  it("renders credential fields", () => {
    render(<PluginsConfigure />);

    expect(screen.getByLabelText(/API Key/)).toBeInTheDocument();
  });

  it("renders setting fields", () => {
    render(<PluginsConfigure />);

    expect(screen.getByLabelText(/Import limit/)).toBeInTheDocument();
  });

  it("renders back link", () => {
    render(<PluginsConfigure />);

    const backLink = screen.getByRole("link", {
      name: /pages.plugins.configuration.backToPlugins/i,
    });
    expect(backLink).toHaveAttribute("href", "/plugins");
  });

  it("renders credentials section header", () => {
    render(<PluginsConfigure />);

    expect(
      screen.getByText("pages.plugins.configuration.credentialsSection")
    ).toBeInTheDocument();
  });

  it("renders settings section header", () => {
    render(<PluginsConfigure />);

    expect(
      screen.getByText("pages.plugins.configuration.settingsSection")
    ).toBeInTheDocument();
  });

  it("renders save buttons for credentials and settings", () => {
    render(<PluginsConfigure />);

    expect(
      screen.getByRole("button", {
        name: "pages.plugins.configuration.saveCredentials",
      })
    ).toBeInTheDocument();
    expect(
      screen.getByRole("button", {
        name: "pages.plugins.configuration.saveSettings",
      })
    ).toBeInTheDocument();
  });
});
