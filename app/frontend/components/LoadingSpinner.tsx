import { cn } from "@/lib/utils";

type SpinnerSize = "sm" | "md" | "lg";

interface LoadingSpinnerProps {
  size?: SpinnerSize;
  className?: string;
}

const sizeClasses: Record<SpinnerSize, string> = {
  sm: "w-4 h-4 border-2",
  md: "w-8 h-8 border-2",
  lg: "w-12 h-12 border-3",
};

export function LoadingSpinner({
  size = "md",
  className,
}: LoadingSpinnerProps) {
  return (
    <div
      className={cn(
        "animate-spin rounded-full border-stone-200 border-t-stone-600",
        sizeClasses[size],
        className
      )}
      role="status"
      aria-label="Loading"
      data-testid="loading-spinner"
    >
      <span className="sr-only">Loading...</span>
    </div>
  );
}

interface LoadingSpinnerContainerProps {
  size?: SpinnerSize;
  className?: string;
}

export function LoadingSpinnerContainer({
  size = "md",
  className,
}: LoadingSpinnerContainerProps) {
  return (
    <div
      className={cn("flex items-center justify-center py-12", className)}
      data-testid="loading-spinner-container"
    >
      <LoadingSpinner size={size} />
    </div>
  );
}
