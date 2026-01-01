import * as React from "react";

import { cn } from "@/lib/utils";

interface InputWithAddonProps
  extends React.InputHTMLAttributes<HTMLInputElement> {
  startAddon?: React.ReactNode;
  endAddon?: React.ReactNode;
}

const InputWithAddon = React.forwardRef<HTMLInputElement, InputWithAddonProps>(
  ({ className, startAddon, endAddon, ...props }, ref) => {
    return (
      <div className="flex">
        {startAddon && (
          <span className="inline-flex items-center px-3 border border-r-0 border-stone-200 rounded-l-lg bg-stone-100 text-stone-500 text-sm">
            {startAddon}
          </span>
        )}
        <input
          className={cn(
            "flex h-9 w-full border border-input bg-transparent px-3 py-1 text-base shadow-sm transition-colors file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50 md:text-sm",
            startAddon && "rounded-l-none",
            endAddon && "rounded-r-none",
            !startAddon && !endAddon && "rounded-md",
            startAddon && !endAddon && "rounded-r-lg",
            !startAddon && endAddon && "rounded-l-lg",
            className
          )}
          ref={ref}
          {...props}
        />
        {endAddon && (
          <span className="inline-flex items-center px-3 border border-l-0 border-stone-200 rounded-r-lg bg-stone-100 text-stone-500 text-sm">
            {endAddon}
          </span>
        )}
      </div>
    );
  }
);
InputWithAddon.displayName = "InputWithAddon";

export { InputWithAddon };
