import { ReactNode } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { cn } from "@/lib/utils";

interface MobileCardDetail {
  label: string;
  value: ReactNode;
}

interface MobileCardProps {
  title: ReactNode;
  subtitle?: ReactNode;
  details?: MobileCardDetail[];
  onClick?: () => void;
  action?: ReactNode;
  className?: string;
}

export function MobileCard({
  title,
  subtitle,
  details,
  onClick,
  action,
  className,
}: MobileCardProps) {
  return (
    <Card
      className={cn(
        "bg-white border-stone-200",
        onClick && "cursor-pointer hover:bg-stone-50 transition-colors",
        className
      )}
      onClick={onClick}
      data-testid="mobile-card"
    >
      <CardContent className="p-4 min-h-11">
        <div className="flex items-start justify-between gap-3">
          <div className="flex-1 min-w-0">
            <div className="font-medium text-stone-900 truncate">{title}</div>
            {subtitle && (
              <div className="text-sm text-stone-500 mt-0.5">{subtitle}</div>
            )}
          </div>
          {action && (
            <div
              className="flex-shrink-0"
              onClick={(e) => e.stopPropagation()}
            >
              {action}
            </div>
          )}
        </div>
        {details && details.length > 0 && (
          <div className="mt-3 pt-3 border-t border-stone-100 grid grid-cols-2 gap-x-4 gap-y-2">
            {details.map((detail, index) => (
              <div key={index} className="text-sm">
                <span className="text-stone-500">{detail.label}: </span>
                <span className="text-stone-900 font-medium">
                  {detail.value}
                </span>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
