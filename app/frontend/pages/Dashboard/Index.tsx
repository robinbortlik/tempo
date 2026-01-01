import { Head, usePage } from "@inertiajs/react";
import { useEffect } from "react";
import { toast } from "sonner";
import { Toaster } from "@/components/ui/sonner";

import { StatCard } from "./components/StatCard";
import { TimeByClientChart } from "./components/TimeByClientChart";
import { TimeByProjectChart } from "./components/TimeByProjectChart";
import { EarningsChart } from "./components/EarningsChart";
import { HoursTrendChart } from "./components/HoursTrendChart";
import { UnbilledByClientTable } from "./components/UnbilledByClientTable";

interface UnbilledClient {
  id: number;
  name: string;
  currency: string;
  project_count: number;
  total_hours: number;
  total_amount: number;
  average_rate: number;
}

interface ClientHours {
  id: number;
  name: string;
  hours: number;
}

interface ProjectHours {
  id: number;
  name: string;
  hours: number;
}

interface MonthlyEarnings {
  month: string;
  amount: number;
}

interface MonthlyHours {
  month: string;
  hours: number;
}

interface PageProps {
  stats: {
    hours_this_week: number;
    hours_this_month: number;
    unbilled_hours: number;
    unbilled_amounts: Record<string, number>;
    unbilled_by_client: UnbilledClient[];
  };
  charts: {
    time_by_client: ClientHours[];
    time_by_project: ProjectHours[];
    earnings_over_time: MonthlyEarnings[];
    hours_trend: MonthlyHours[];
  };
  flash: {
    alert?: string;
    notice?: string;
  };
  [key: string]: unknown;
}

const CURRENCY_SYMBOLS: Record<string, string> = {
  EUR: "\u20AC",
  USD: "$",
  GBP: "\u00A3",
  CZK: "K\u010D",
};

function formatCurrencyAmount(amount: number, currency: string): string {
  const symbol = CURRENCY_SYMBOLS[currency] || currency;
  return `${symbol}${amount.toLocaleString(undefined, {
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  })}`;
}

export default function DashboardIndex() {
  const { stats, charts, flash } = usePage<PageProps>().props;

  useEffect(() => {
    if (flash.notice) {
      toast.success(flash.notice);
    }
    if (flash.alert) {
      toast.error(flash.alert);
    }
  }, [flash.notice, flash.alert]);

  // Convert unbilled_amounts object to array for display
  const unbilledAmountEntries = Object.entries(
    stats.unbilled_amounts || {}
  ).sort(([, a], [, b]) => Number(b) - Number(a));

  return (
    <>
      <Head title="Dashboard" />
      <Toaster position="top-right" />

      <div className="p-8">
        <div className="mb-8">
          <h1 className="text-2xl font-semibold text-stone-900">Dashboard</h1>
          <p className="text-stone-500 mt-1">Overview of your time tracking</p>
        </div>

        {/* Stats Cards Row */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          <StatCard
            title="This Week"
            value={stats.hours_this_week.toFixed(1)}
            suffix="hrs"
          />

          <StatCard
            title="This Month"
            value={stats.hours_this_month.toFixed(1)}
            suffix="hrs"
          />

          <StatCard
            title="Unbilled Hours"
            value={stats.unbilled_hours.toFixed(1)}
            suffix="hrs"
            indicator={
              stats.unbilled_hours > 0 ? (
                <span className="w-2 h-2 bg-amber-400 rounded-full" />
              ) : undefined
            }
          />

          <StatCard title="Unbilled Total" value="" highlight>
            {unbilledAmountEntries.length === 0 ? (
              <p className="text-3xl font-semibold tabular-nums text-amber-900">
                -
              </p>
            ) : unbilledAmountEntries.length === 1 ? (
              <p className="text-3xl font-semibold tabular-nums text-amber-900">
                {formatCurrencyAmount(
                  Number(unbilledAmountEntries[0][1]),
                  unbilledAmountEntries[0][0]
                )}
              </p>
            ) : (
              <div className="space-y-1">
                {unbilledAmountEntries.map(([currency, amount]) => (
                  <p
                    key={currency}
                    className="text-lg font-semibold tabular-nums text-amber-900"
                  >
                    {formatCurrencyAmount(Number(amount), currency)}
                    <span className="text-sm font-normal text-amber-700 ml-1">
                      {currency}
                    </span>
                  </p>
                ))}
              </div>
            )}
          </StatCard>
        </div>

        {/* Charts Row 1 */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
          <TimeByClientChart data={charts.time_by_client} />
          <EarningsChart data={charts.earnings_over_time} />
        </div>

        {/* Charts Row 2 */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          <TimeByProjectChart data={charts.time_by_project} />
          <HoursTrendChart data={charts.hours_trend} />
        </div>

        {/* Unbilled by Client Table */}
        <UnbilledByClientTable data={stats.unbilled_by_client} />
      </div>
    </>
  );
}
