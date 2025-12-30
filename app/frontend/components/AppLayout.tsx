import { Head } from "@inertiajs/react";
import { ReactNode } from "react";
import { Toaster } from "@/components/ui/sonner";
import Sidebar from "./Sidebar";
import Header from "./Header";

interface AppLayoutProps {
  children: ReactNode;
  title?: string;
}

export default function AppLayout({ children, title }: AppLayoutProps) {
  const pageTitle = title ? `${title} - Tempo` : "Tempo";

  return (
    <>
      <Head title={pageTitle} />
      <Toaster position="top-right" />

      <div className="min-h-screen bg-stone-50 flex" data-testid="app-layout">
        {/* Desktop Sidebar - fixed position */}
        <div className="hidden lg:block lg:fixed lg:inset-y-0 lg:z-50 lg:w-60">
          <Sidebar />
        </div>

        {/* Main content area */}
        <div className="flex-1 lg:ml-60 flex flex-col min-h-screen">
          {/* Mobile Header */}
          <Header />

          {/* Page Content */}
          <main className="flex-1">{children}</main>
        </div>
      </div>
    </>
  );
}
