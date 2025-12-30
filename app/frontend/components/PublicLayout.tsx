import { Head } from "@inertiajs/react";
import { ReactNode } from "react";

interface PublicLayoutProps {
  children: ReactNode;
  title?: string;
}

/**
 * A minimal layout for public-facing pages (no authentication nav)
 * Used for client report portal and other unauthenticated pages
 */
export default function PublicLayout({ children, title }: PublicLayoutProps) {
  const pageTitle = title ? `${title} - Tempo` : "Tempo";

  return (
    <>
      <Head title={pageTitle} />
      <div className="min-h-screen bg-white">{children}</div>
    </>
  );
}
