import { Link, usePage } from "@inertiajs/react";

interface BreadcrumbItem {
  label: string;
  href?: string;
}

interface BreadcrumbProps {
  items?: BreadcrumbItem[];
}

const ChevronIcon = () => (
  <svg
    className="w-4 h-4 text-stone-400"
    fill="none"
    stroke="currentColor"
    viewBox="0 0 24 24"
  >
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={1.5}
      d="M9 5l7 7-7 7"
    />
  </svg>
);

// Auto-generate breadcrumbs from URL if not provided
function generateBreadcrumbs(url: string): BreadcrumbItem[] {
  const segments = url.split("/").filter(Boolean);
  const items: BreadcrumbItem[] = [{ label: "Home", href: "/" }];

  // Route mapping for friendly names
  const routeNames: Record<string, string> = {
    time_entries: "Time Entries",
    clients: "Clients",
    projects: "Projects",
    invoices: "Invoices",
    settings: "Settings",
    dashboard: "Dashboard",
    new: "New",
    edit: "Edit",
  };

  let currentPath = "";
  segments.forEach((segment, index) => {
    currentPath += `/${segment}`;

    // Skip numeric IDs in breadcrumbs or show as part of previous item
    if (/^\d+$/.test(segment)) {
      return;
    }

    const label = routeNames[segment] || segment.charAt(0).toUpperCase() + segment.slice(1);

    // Last item doesn't get a link
    if (index === segments.length - 1) {
      items.push({ label });
    } else {
      items.push({ label, href: currentPath });
    }
  });

  return items;
}

export default function Breadcrumb({ items }: BreadcrumbProps) {
  const { url } = usePage();

  // Use provided items or generate from URL
  const breadcrumbItems = items || generateBreadcrumbs(url);

  // Don't show breadcrumbs on home/dashboard
  if (breadcrumbItems.length <= 1) {
    return null;
  }

  return (
    <nav
      aria-label="Breadcrumb"
      className="flex items-center gap-1 text-sm text-stone-500 mb-4"
      data-testid="breadcrumb"
    >
      {breadcrumbItems.map((item, index) => (
        <div key={index} className="flex items-center gap-1">
          {index > 0 && <ChevronIcon />}
          {item.href ? (
            <Link
              href={item.href}
              className="hover:text-stone-900 transition-colors"
            >
              {item.label}
            </Link>
          ) : (
            <span className="text-stone-900 font-medium">{item.label}</span>
          )}
        </div>
      ))}
    </nav>
  );
}
