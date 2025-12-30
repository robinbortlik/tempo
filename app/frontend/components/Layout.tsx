import { ReactNode } from "react";
import AppLayout from "./AppLayout";

interface LayoutProps {
  children: ReactNode;
  title?: string;
}

/**
 * Main application layout wrapper.
 * Delegates to AppLayout for the full navigation shell.
 */
export default function Layout({ children, title }: LayoutProps) {
  return <AppLayout title={title}>{children}</AppLayout>;
}
