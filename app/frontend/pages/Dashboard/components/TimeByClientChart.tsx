import {
  PieChart,
  Pie,
  Cell,
  ResponsiveContainer,
  Legend,
  Tooltip,
} from "recharts";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";

interface ClientHours {
  id: number;
  name: string;
  hours: number;
}

interface TimeByClientChartProps {
  data: ClientHours[];
}

const COLORS = [
  "#1c1917", // stone-900
  "#78716c", // stone-500
  "#a8a29e", // stone-400
  "#d6d3d1", // stone-300
  "#e7e5e4", // stone-200
];

export function TimeByClientChart({ data }: TimeByClientChartProps) {
  const totalHours = data.reduce((sum, client) => sum + client.hours, 0);

  const chartData = data.slice(0, 5).map((client) => ({
    ...client,
    percentage:
      totalHours > 0 ? ((client.hours / totalHours) * 100).toFixed(1) : "0",
  }));

  if (data.length === 0) {
    return (
      <Card className="bg-white border-stone-200">
        <CardHeader>
          <CardTitle className="text-stone-900">Hours by Client</CardTitle>
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
        <CardTitle className="text-stone-900">Hours by Client</CardTitle>
      </CardHeader>
      <CardContent className="h-48">
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie
              data={chartData}
              cx="30%"
              cy="50%"
              innerRadius={40}
              outerRadius={70}
              paddingAngle={2}
              dataKey="hours"
              nameKey="name"
            >
              {chartData.map((_, index) => (
                <Cell
                  key={`cell-${index}`}
                  fill={COLORS[index % COLORS.length]}
                />
              ))}
            </Pie>
            <Tooltip
              formatter={(value) => [
                `${Math.round(Number(value))} hrs`,
                "Hours",
              ]}
              contentStyle={{
                backgroundColor: "#fafaf9",
                border: "1px solid #e7e5e4",
                borderRadius: "8px",
              }}
            />
            <Legend
              layout="vertical"
              verticalAlign="middle"
              align="right"
              wrapperStyle={{ paddingLeft: "20px" }}
              formatter={(value) => {
                const item = chartData.find((c) => c.name === value);
                return (
                  <span className="text-sm text-stone-600">
                    {value}
                    <span className="ml-2 font-medium text-stone-900 tabular-nums">
                      {item?.percentage}%
                    </span>
                  </span>
                );
              }}
            />
          </PieChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}
