import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  Cell,
} from "recharts";
import { useTranslation } from "react-i18next";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";

interface ProjectHours {
  id: number;
  name: string;
  hours: number;
}

interface TimeByProjectChartProps {
  data: ProjectHours[];
}

const COLORS = [
  "#1c1917", // stone-900
  "#292524", // stone-800
  "#44403c", // stone-700
  "#57534e", // stone-600
  "#78716c", // stone-500
  "#a8a29e", // stone-400
  "#d6d3d1", // stone-300
  "#e7e5e4", // stone-200
  "#f5f5f4", // stone-100
  "#fafaf9", // stone-50
];

export function TimeByProjectChart({ data }: TimeByProjectChartProps) {
  const { t } = useTranslation();
  const chartData = data.slice(0, 8).map((project) => ({
    ...project,
    // Truncate long project names
    displayName:
      project.name.length > 15
        ? project.name.substring(0, 12) + "..."
        : project.name,
  }));

  if (data.length === 0) {
    return (
      <Card className="bg-white border-stone-200">
        <CardHeader>
          <CardTitle className="text-stone-900">
            {t("pages.dashboard.charts.hoursByProject")}
          </CardTitle>
        </CardHeader>
        <CardContent className="h-48 flex items-center justify-center text-stone-500">
          {t("pages.dashboard.charts.noTimeEntries")}
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="bg-white border-stone-200">
      <CardHeader>
        <CardTitle className="text-stone-900">
          {t("pages.dashboard.charts.hoursByProject")}
        </CardTitle>
      </CardHeader>
      <CardContent className="h-48">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart
            data={chartData}
            layout="vertical"
            margin={{ top: 5, right: 30, left: 10, bottom: 5 }}
          >
            <XAxis type="number" axisLine={false} tickLine={false} />
            <YAxis
              type="category"
              dataKey="displayName"
              axisLine={false}
              tickLine={false}
              width={100}
              tick={{ fontSize: 12 }}
            />
            <Tooltip
              formatter={(value) => [
                `${Math.round(Number(value))} hrs`,
                t("common.hours"),
              ]}
              labelFormatter={(label, payload) => {
                if (payload && payload[0]) {
                  return payload[0].payload.name;
                }
                return label;
              }}
              contentStyle={{
                backgroundColor: "#fafaf9",
                border: "1px solid #e7e5e4",
                borderRadius: "8px",
              }}
            />
            <Bar dataKey="hours" radius={[0, 4, 4, 0]}>
              {chartData.map((_, index) => (
                <Cell
                  key={`cell-${index}`}
                  fill={COLORS[index % COLORS.length]}
                />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}
