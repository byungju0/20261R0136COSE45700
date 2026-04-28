import {
  Bar,
  BarChart as RechartsBarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';

interface BarChartProps {
  data: Array<{ name: string; value: number }>;
  /** CSS color (CSS variable, hex, hsl, oklch). Defaults to --primary token. */
  color?: string;
  height?: number;
}

export function BarChart({
  data,
  color = 'var(--primary)',
  height = 260,
}: BarChartProps) {
  return (
    <ResponsiveContainer width="100%" height={height}>
      <RechartsBarChart data={data} margin={{ top: 16, right: 16, bottom: 16, left: 0 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
        <XAxis dataKey="name" stroke="var(--muted-foreground)" fontSize={12} />
        <YAxis allowDecimals={false} stroke="var(--muted-foreground)" fontSize={12} />
        <Tooltip />
        <Bar dataKey="value" fill={color} radius={[4, 4, 0, 0]} />
      </RechartsBarChart>
    </ResponsiveContainer>
  );
}
