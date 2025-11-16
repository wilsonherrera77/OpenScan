import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/reporting_service.dart';

/// Productivity Dashboard Widget
///
/// Enhanced dashboard showing real-time productivity metrics:
/// - Documents per day with trend analysis
/// - Average processing time per document
/// - Quality score trends
/// - Daily/weekly/monthly comparisons
/// - Interactive charts with fl_chart
class ProductivityDashboardWidget extends StatelessWidget {
  final ProductivityMetrics metrics;
  final List<DailyStatistics>? weeklyTrends;
  final bool showDetailedCharts;

  const ProductivityDashboardWidget({
    super.key,
    required this.metrics,
    this.weeklyTrends,
    this.showDetailedCharts = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildMetricsGrid(),
            if (showDetailedCharts && weeklyTrends != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildTrendChart(),
            ],
            const SizedBox(height: 16),
            _buildPerformanceIndicators(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.trending_up,
            color: Colors.teal,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard de Productividad',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Métricas en tiempo real',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildMetricCard(
          title: 'Docs/Día',
          value: metrics.documentsPerDay.toStringAsFixed(1),
          icon: Icons.description,
          color: Colors.blue,
          trend: _calculateTrend(metrics.documentsPerDay, 10.0),
        ),
        _buildMetricCard(
          title: 'Tiempo Promedio',
          value: '${metrics.avgTimePerDocument.toStringAsFixed(1)} min',
          icon: Icons.timer,
          color: Colors.orange,
          trend: _calculateTrend(5.0, metrics.avgTimePerDocument),
        ),
        _buildMetricCard(
          title: 'Calidad',
          value: '${metrics.avgQualityScore.toStringAsFixed(0)}%',
          icon: Icons.star,
          color: Colors.green,
          trend: _calculateTrend(metrics.avgQualityScore, 85.0),
        ),
        _buildMetricCard(
          title: 'Total Docs',
          value: '${metrics.totalDocuments}',
          icon: Icons.file_copy,
          color: Colors.purple,
          trend: TrendDirection.neutral,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    TrendDirection trend = TrendDirection.neutral,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              if (trend != TrendDirection.neutral) _buildTrendIndicator(trend, color),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(TrendDirection trend, Color baseColor) {
    IconData iconData;
    Color color;

    switch (trend) {
      case TrendDirection.up:
        iconData = Icons.arrow_upward;
        color = Colors.green;
        break;
      case TrendDirection.down:
        iconData = Icons.arrow_downward;
        color = Colors.red;
        break;
      case TrendDirection.neutral:
        iconData = Icons.remove;
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(iconData, color: color, size: 16),
    );
  }

  TrendDirection _calculateTrend(double current, double baseline) {
    if (current > baseline * 1.1) return TrendDirection.up;
    if (current < baseline * 0.9) return TrendDirection.down;
    return TrendDirection.neutral;
  }

  Widget _buildTrendChart() {
    if (weeklyTrends == null || weeklyTrends!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tendencia Semanal',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _buildLineChart(),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    final spots = weeklyTrends!
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.documentCount.toDouble()))
        .toList();

    final maxY = weeklyTrends!
        .map((d) => d.documentCount)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: maxY > 0 ? maxY / 4 : 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= 0 && value.toInt() < weeklyTrends!.length) {
                  final date = weeklyTrends![value.toInt()].date;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY > 0 ? maxY / 4 : 1,
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        minX: 0,
        maxX: (weeklyTrends!.length - 1).toDouble(),
        minY: 0,
        maxY: maxY > 0 ? maxY * 1.2 : 10,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: const LinearGradient(
              colors: [Colors.teal, Colors.tealAccent],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.teal,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.teal.withOpacity(0.2),
                  Colors.teal.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.teal.withOpacity(0.9),
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                if (barSpot.x.toInt() >= 0 &&
                    barSpot.x.toInt() < weeklyTrends!.length) {
                  final date = weeklyTrends![barSpot.x.toInt()].date;
                  return LineTooltipItem(
                    '${date.day}/${date.month}\n${barSpot.y.toInt()} docs',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceIndicators() {
    final efficiency = _calculateEfficiency();
    final consistency = _calculateConsistency();

    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildIndicatorBar(
                label: 'Eficiencia',
                value: efficiency,
                color: efficiency >= 0.7 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildIndicatorBar(
                label: 'Consistencia',
                value: consistency,
                color: consistency >= 0.7 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIndicatorBar({
    required String label,
    required double value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  double _calculateEfficiency() {
    // Basado en documentos por hora vs objetivo
    final docsPerHour = metrics.documentsPerHour;
    final target = 8.0; // 8 documentos por hora objetivo
    return (docsPerHour / target).clamp(0.0, 1.0);
  }

  double _calculateConsistency() {
    // Basado en calidad promedio
    return (metrics.avgQualityScore / 100).clamp(0.0, 1.0);
  }
}

/// Trend direction enum
enum TrendDirection {
  up,
  down,
  neutral,
}

/// Extension for ProductivityMetrics
class ProductivityMetrics {
  final int totalDocuments;
  final int totalPersons;
  final double totalTimeHours;
  final double avgQualityScore;
  final double documentsPerHour;
  final double documentsPerDay;
  final double avgTimePerDocument;

  ProductivityMetrics({
    required this.totalDocuments,
    required this.totalPersons,
    required this.totalTimeHours,
    required this.avgQualityScore,
    required this.documentsPerHour,
    required this.documentsPerDay,
    required this.avgTimePerDocument,
  });
}
