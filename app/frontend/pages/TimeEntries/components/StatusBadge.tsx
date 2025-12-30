interface StatusBadgeProps {
  status: "unbilled" | "invoiced";
}

export default function StatusBadge({ status }: StatusBadgeProps) {
  if (status === "unbilled") {
    return (
      <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700">
        Unbilled
      </span>
    );
  }

  return (
    <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700">
      Invoiced
    </span>
  );
}
