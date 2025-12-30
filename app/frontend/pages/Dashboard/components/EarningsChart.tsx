import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";

interface MonthlyEarnings {
  month: string;
  amount: number;
}

interface EarningsChartProps {
  data: MonthlyEarnings[];
}

export function EarningsChart({ data }: EarningsChartProps) {
  const hasData = data.some((d) => d.amount > 0);

  if (!hasData) {
    return (
      <Card className="bg-white border-stone-200">
        <CardHeader>
          <CardTitle className="text-stone-900">Monthly Earnings</CardTitle>
        </CardHeader>
        <CardContent className="h-48 flex items-center justify-center text-stone-500">
          No finalized invoices yet
        </CardContent>
      </Card>
    );
  }

  const formatAmount = (value: number) => {
    if (value >= 1000) {
      return `${(value / 1000).toFixed(1)}k`;
    }
    return value.toFixed(0);
  };

  return (
    <Card className="bg-white border-stone-200">
      <CardHeader>
        <CardTitle className="text-stone-900">Monthly Earnings</CardTitle>
      </CardHeader>
      <CardContent className="h-48">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart
            data={data}
            margin={{ top: 10, right: 10, left: 0, bottom: 0 }}
          >
            <defs>
              <linearGradient id="earningsGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#1c1917" stopOpacity={0.2} />
                <stop offset="95%" stopColor="#1c1917" stopOpacity={0} />
              </linearGradient>
            </defs>
            <XAxis
              dataKey="month"
              axisLine={false}
              tickLine={false}
              tick={{ fontSize: 11, fill: "#78716c" }}
              tickFormatter={(value) => value.split(" ")[0]}
            />
            <YAxis
              axisLine={false}
              tickLine={false}
              tick={{ fontSize: 11, fill: "#78716c" }}
              tickFormatter={formatAmount}
              width={45}
            />
            <Tooltip
              formatter={(value) => [
                new Intl.NumberFormat("en-US", {
                  minimumFractionDigits: 2,
                  maximumFractionDigits: 2,
                }).format(Number(value)),
                "Earnings",
              ]}
              contentStyle={{
                backgroundColor: "#fafaf9",
                border: "1px solid #e7e5e4",
                borderRadius: "8px",
              }}
            />
            <Area
              type="monotone"
              dataKey="amount"
              stroke="#1c1917"
              strokeWidth={2}
              fill="url(#earningsGradient)"
            />
          </AreaChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}
