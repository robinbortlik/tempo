import { ReactNode } from "react";
import { cn } from "@/lib/utils";

interface EmptyStateProps {
  icon: ReactNode;
  title: string;
  description: string;
  action?: ReactNode;
  className?: string;
}

export function EmptyState({
  icon,
  title,
  description,
  action,
  className,
}: EmptyStateProps) {
  return (
    <div
      className={cn(
        "flex flex-col items-center justify-center py-12 px-6 text-center",
        className
      )}
      data-testid="empty-state"
    >
      <div className="w-12 h-12 bg-stone-100 rounded-full flex items-center justify-center text-stone-500 mb-4">
        {icon}
      </div>
      <h3 className="font-medium text-stone-900 mb-1">{title}</h3>
      <p className="text-stone-500 text-sm max-w-sm mb-4">{description}</p>
      {action && <div>{action}</div>}
    </div>
  );
}
