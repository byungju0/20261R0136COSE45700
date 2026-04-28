import {
  Cell,
  Legend,
  Pie,
  PieChart as RechartsPieChart,
  ResponsiveContainer,
  Tooltip,
} from 'recharts';
import { CHART_PALETTE_VARS } from './colors';

interface PieChartProps {
  data: Array<{ name: string; value: number }>;
  /** Optional override for slice colors. Defaults to CHART_PALETTE_VARS (CSS variables). */
  colors?: readonly string[];
  height?: number;
}

export function PieChart({
  data,
  colors = CHART_PALETTE_VARS,
  height = 260,
}: PieChartProps) {
  return (
    <ResponsiveContainer width="100%" height={height}>
      <RechartsPieChart>
        <Pie
          data={data}
          dataKey="value"
          nameKey="name"
          cx="50%"
          cy="50%"
          outerRadius={90}
          label
        >
          {data.map((entry, idx) => (
            <Cell key={entry.name} fill={colors[idx % colors.length]} />
          ))}
        </Pie>
        <Tooltip />
        <Legend />
      </RechartsPieChart>
    </ResponsiveContainer>
  );
}
