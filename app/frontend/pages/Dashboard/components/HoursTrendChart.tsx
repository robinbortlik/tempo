import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";

interface MonthlyHours {
  month: string;
  hours: number;
}

interface HoursTrendChartProps {
  data: MonthlyHours[];
}

export function HoursTrendChart({ data }: HoursTrendChartProps) {
  const hasData = data.some((d) => d.hours > 0);

  if (!hasData) {
    return (
      <Card className="bg-white border-stone-200">
        <CardHeader>
          <CardTitle className="text-stone-900">Hours Trend</CardTitle>
        </CardHeader>
        <CardContent className="h-48 flex items-center justify-center text-stone-500">
          No time entries recorded yet
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="bg-white border-stone-200">
      <CardHeader>
        <CardTitle className="text-stone-900">Hours Trend</CardTitle>
      </CardHeader>
      <CardContent className="h-48">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart
            data={data}
            margin={{ top: 10, right: 10, left: 0, bottom: 0 }}
          >
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
              width={35}
            />
            <Tooltip
              formatter={(value) => [`${Number(value).toFixed(1)} hrs`, "Hours"]}
              contentStyle={{
                backgroundColor: "#fafaf9",
                border: "1px solid #e7e5e4",
                borderRadius: "8px",
              }}
            />
            <Line
              type="monotone"
              dataKey="hours"
              stroke="#78716c"
              strokeWidth={2}
              dot={{ fill: "#78716c", strokeWidth: 0, r: 4 }}
              activeDot={{ fill: "#1c1917", strokeWidth: 0, r: 6 }}
            />
          </LineChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}
