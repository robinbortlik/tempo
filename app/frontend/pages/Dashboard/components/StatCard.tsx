import { Card } from "@/components/ui/card";
import { cn } from "@/lib/utils";

interface StatCardProps {
  title: string;
  value: string | number;
  suffix?: string;
  highlight?: boolean;
  indicator?: React.ReactNode;
  children?: React.ReactNode;
}

export function StatCard({
  title,
  value,
  suffix,
  highlight = false,
  indicator,
  children,
}: StatCardProps) {
  return (
    <Card
      className={cn(
        "p-5 transition-all hover:shadow-md",
        highlight
          ? "bg-amber-50 border-amber-200"
          : "bg-white border-stone-200"
      )}
    >
      <div className="flex items-center justify-between mb-3">
        <span
          className={cn(
            "text-sm font-medium",
            highlight ? "text-amber-700" : "text-stone-500"
          )}
        >
          {title}
        </span>
        {indicator}
      </div>
      {children ? (
        children
      ) : (
        <p
          className={cn(
            "text-3xl font-semibold tabular-nums",
            highlight ? "text-amber-900" : "text-stone-900"
          )}
        >
          {value}
          {suffix && (
            <span
              className={cn(
                "text-lg ml-1",
                highlight ? "text-amber-600" : "text-stone-400"
              )}
            >
              {suffix}
            </span>
          )}
        </p>
      )}
    </Card>
  );
}
