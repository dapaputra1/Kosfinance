import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class SpendingPieChart extends StatefulWidget {
  final List<dynamic> categoryExpenses;

  const SpendingPieChart({
    super.key,
    required this.categoryExpenses,
  });

  @override
  State<SpendingPieChart> createState() => _SpendingPieChartState();
}

class _SpendingPieChartState extends State<SpendingPieChart> {
  int _touchedIndex = -1;

  static const List<Color> _palette = [
    Color(0xFFFF6384),
    Color(0xFF36A2EB),
    Color(0xFFFFCE56),
    Color(0xFF4BC0C0),
    Color(0xFF9966FF),
    Color(0xFFFF9F40),
    Color(0xFF00C49F),
    Color(0xFFFFBB28),
    Color(0xFFFF8042),
    Color(0xFF8884D8),
  ];

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Filter items with total > 0
    final items = widget.categoryExpenses.where((item) {
      final total = (item['total'] as num?)?.toDouble() ?? 0;
      return total > 0;
    }).toList();

    final double grandTotal = items.fold(0.0, (sum, item) {
      return sum + ((item['total'] as num?)?.toDouble() ?? 0.0);
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.pie_chart, color: Colors.blue.shade700, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Expense Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty || grandTotal <= 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.donut_small_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'No expenses recorded for this month',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex = pieTouchResponse
                                  .touchedSection!
                                  .touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: List.generate(items.length, (i) {
                          final isTouched = i == _touchedIndex;
                          final fontSize = isTouched ? 16.0 : 12.0;
                          final radius = isTouched ? 65.0 : 55.0;
                          final color = _palette[i % _palette.length];
                          final item = items[i];
                          final total = (item['total'] as num?)?.toDouble() ?? 0.0;
                          final percentage = (total / grandTotal) * 100;

                          return PieChartSectionData(
                            color: color,
                            value: total,
                            title: percentage >= 5
                                ? '${percentage.toStringAsFixed(0)}%'
                                : '',
                            radius: radius,
                            titleStyle: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: const [
                                Shadow(color: Colors.black38, blurRadius: 2),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Legend
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final color = _palette[i % _palette.length];
                      final total = (item['total'] as num?)?.toDouble() ?? 0.0;
                      final percentage = (total / grandTotal) * 100;

                      return Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['name'] ?? 'Category',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            currencyFormat.format(total),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
