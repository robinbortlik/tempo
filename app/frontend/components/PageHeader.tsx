import { ReactNode } from "react";
import { cn } from "@/lib/utils";

interface PageHeaderProps {
  title: string;
  subtitle?: string;
  children?: ReactNode;
  className?: string;
}

export function PageHeader({
  title,
  subtitle,
  children,
  className,
}: PageHeaderProps) {
  return (
    <div
      className={cn(
        "mb-8 flex flex-col gap-4 md:flex-row md:items-center md:justify-between",
        className
      )}
      data-testid="page-header"
    >
      <div>
        <h1 className="text-2xl font-semibold text-stone-900">{title}</h1>
        {subtitle && <p className="text-stone-500 mt-1">{subtitle}</p>}
      </div>
      {children && (
        <div className="flex items-center gap-2 [&>*]:w-full [&>*]:md:w-auto">
          {children}
        </div>
      )}
    </div>
  );
}
