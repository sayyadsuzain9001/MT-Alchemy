import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

const chartPalette = [
  purple,
  royalBlue,
  Color(0xFF0E7490),
  Color(0xFFB7791F),
  Color(0xFF2E7D32),
  Color(0xFFC2410C),
];

/// Vertical bars for labelled values (e.g. progress by department).
class LabelledBarChart extends StatelessWidget {
  const LabelledBarChart({
    super.key,
    required this.values,
    this.maxY,
    this.suffix = '',
    this.height = 220,
    this.color = purple,
    this.emptyText = 'No data yet.',
  });
  final String emptyText;
  final List<(String, double)> values;
  final double? maxY;
  final String suffix;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return SizedBox(
        height: height / 2,
        child: const Center(child: Text('No data yet.')),
      );
    }
    final highest = values.map((v) => v.$2).reduce((a, b) => a > b ? a : b);
    if (maxY == null && highest <= 0) {
      return SizedBox(
        height: height / 2,
        child: Center(
          child: Text(emptyText, style: const TextStyle(color: Colors.black54)),
        ),
      );
    }
    // Round the axis up to a multiple of 4 so grid labels are whole numbers.
    final top = maxY ?? ((highest * 1.15) / 4).ceilToDouble() * 4;
    return Semantics(
      label:
          'Bar chart: ${values.map((v) => '${v.$1} ${v.$2.round()}$suffix').join(', ')}',
      child: SizedBox(
        height: height,
        child: BarChart(
          BarChartData(
            maxY: top,
            alignment: BarChartAlignment.spaceAround,
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: top / 4,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: Color(0xFFECE8F5), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => deepBlue,
                getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                  '${values[group.x].$1}\n${rod.toY.round()}$suffix',
                  const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: top / 4,
                  getTitlesWidget: (v, meta) => Text(
                    '${v.round()}$suffix',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  getTitlesWidget: (v, meta) {
                    final i = v.toInt();
                    if (i < 0 || i >= values.length) return const SizedBox();
                    final label = values[i].$1;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        label.length > 12
                            ? '${label.substring(0, 11)}…'
                            : label,
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (final (i, v) in values.indexed)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: v.$2,
                      width: 26,
                      color: color,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: top,
                        color: const Color(0xFFF4F1FB),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Donut chart with a legend.
class StatusDonut extends StatelessWidget {
  const StatusDonut({
    super.key,
    required this.values,
    this.colors = chartPalette,
    this.centerLabel,
  });
  final Map<String, num> values;
  final List<Color> colors;
  final String? centerLabel;

  @override
  Widget build(BuildContext context) {
    final total = values.values.fold<num>(0, (t, v) => t + v);
    final entries = values.entries.toList();
    return Semantics(
      label:
          'Donut chart: ${entries.map((e) => '${e.key} ${e.value}').join(', ')}',
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 16,
        children: [
          SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 52,
                    sections: total == 0
                        ? [
                            PieChartSectionData(
                              value: 1,
                              color: const Color(0xFFECE8F5),
                              radius: 22,
                              showTitle: false,
                            ),
                          ]
                        : [
                            for (final (i, e) in entries.indexed)
                              if (e.value > 0)
                                PieChartSectionData(
                                  value: e.value.toDouble(),
                                  color: colors[i % colors.length],
                                  radius: 22,
                                  showTitle: false,
                                ),
                          ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: deepBlue,
                      ),
                    ),
                    if (centerLabel != null)
                      Text(
                        centerLabel!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, e) in entries.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${e.key}: ${e.value}'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
