import { Link, usePage } from "@inertiajs/react";

interface SidebarProps {
  onNavigate?: () => void;
}

interface NavItemProps {
  href: string;
  icon: React.ReactNode;
  label: string;
  isActive: boolean;
  onClick?: () => void;
}

function NavItem({ href, icon, label, isActive, onClick }: NavItemProps) {
  return (
    <Link
      href={href}
      onClick={onClick}
      className={`nav-item w-full flex items-center gap-3 px-3 py-2 rounded-lg text-left text-sm font-medium transition-all duration-150
        ${
          isActive
            ? "bg-stone-900 text-white"
            : "text-stone-600 hover:bg-stone-100"
        }`}
      data-testid={`nav-${label.toLowerCase().replace(/\s+/g, "-")}`}
    >
      {icon}
      {label}
    </Link>
  );
}

// Icon components matching the mockup style
const DashboardIcon = () => (
  <svg
    className="w-5 h-5"
    fill="none"
    stroke="currentColor"
    viewBox="0 0 24 24"
  >
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={1.5}
      d="M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM4 13a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H5a1 1 0 01-1-1v-6zM16 13a1 1 0 011-1h2a1 1 0 011 1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-6z"
    />
  </svg>
);

const TimeEntriesIcon = () => (
  <svg
    className="w-5 h-5"
    fill="none"
    stroke="currentColor"
    viewBox="0 0 24 24"
  >
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={1.5}
      d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
    />
  </svg>
);

const ClientsIcon = () => (
  <svg
    className="w-5 h-5"
    fill="none"
    stroke="currentColor"
    viewBox="0 0 24 24"
  >
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={1.5}
      d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
    />
  </svg>
);

const ProjectsIcon = () => (
  <svg
    className="w-5 h-5"
    fill="none"
    stroke="currentColor"
    viewBox="0 0 24 24"
  >
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={1.5}
      d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z"
    />
  </svg>
);

const InvoicesIcon = () => (
  <svg
    className="w-5 h-5"
    fill="none"
    stroke="currentColor"
    viewBox="0 0 24 24"
  >
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={1.5}
      d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
    />
  </svg>
);

const SettingsIcon = () => (
  <svg
    className="w-5 h-5"
    fill="none"
    stroke="currentColor"
    viewBox="0 0 24 24"
  >
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={1.5}
      d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
    />
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={1.5}
      d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
    />
  </svg>
);

const LogoutIcon = () => (
  <svg
    className="w-5 h-5"
    fill="none"
    stroke="currentColor"
    viewBox="0 0 24 24"
  >
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={1.5}
      d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"
    />
  </svg>
);

const ClockIcon = () => (
  <svg
    className="w-4 h-4 text-white"
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
);

export default function Sidebar({ onNavigate }: SidebarProps) {
  const { url } = usePage();

  // Helper to check if a path is active
  const isActive = (path: string) => {
    if (path === "/") {
      return url === "/" || url === "/dashboard";
    }
    return url.startsWith(path);
  };

  const mainNavItems = [
    { href: "/", icon: <DashboardIcon />, label: "Dashboard" },
    { href: "/work_entries", icon: <TimeEntriesIcon />, label: "Log Work" },
    { href: "/clients", icon: <ClientsIcon />, label: "Clients" },
    { href: "/projects", icon: <ProjectsIcon />, label: "Projects" },
    { href: "/invoices", icon: <InvoicesIcon />, label: "Invoices" },
  ];

  return (
    <aside
      className="w-60 bg-white border-r border-stone-200 flex flex-col h-full"
      data-testid="sidebar"
    >
      {/* Logo */}
      <div className="p-4 border-b border-stone-200">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 bg-stone-900 rounded-lg flex items-center justify-center">
            <ClockIcon />
          </div>
          <span className="font-semibold text-stone-900">Tempo</span>
        </div>
      </div>

      {/* Main Navigation */}
      <nav className="flex-1 p-3 space-y-1" data-testid="main-nav">
        {mainNavItems.map((item) => (
          <NavItem
            key={item.href}
            href={item.href}
            icon={item.icon}
            label={item.label}
            isActive={isActive(item.href)}
            onClick={onNavigate}
          />
        ))}
      </nav>

      {/* Bottom Navigation */}
      <div className="p-3 border-t border-stone-200 space-y-1">
        <NavItem
          href="/settings"
          icon={<SettingsIcon />}
          label="Settings"
          isActive={isActive("/settings")}
          onClick={onNavigate}
        />

        <Link
          href="/session"
          method="delete"
          as="button"
          className="nav-item w-full flex items-center gap-3 px-3 py-2 rounded-lg text-left text-sm font-medium text-stone-600 hover:bg-stone-100 transition-all duration-150"
          data-testid="nav-sign-out"
          onClick={onNavigate}
        >
          <LogoutIcon />
          Sign out
        </Link>
      </div>
    </aside>
  );
}
