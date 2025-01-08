import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({Key? key}) : super(key: key);

  @override
  _ChartPageState createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  bool _isLoading = true;
  Map<String, double> _monthlyTotals = {};
  Map<String, Map<String, double>> _categoryBreakdowns = {};

  @override
  void initState() {
    super.initState();
    _fetchExpenseData();
  }

  Future<void> _fetchExpenseData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final now = DateTime.now();
    final oneYearAgo = DateTime(now.year, now.month - 11);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(oneYearAgo))
          .where('date', isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(now))
          .get();

      final expenses = querySnapshot.docs.map((doc) => doc.data()).toList();

      final monthlyTotals = <String, double>{};
      final categoryBreakdowns = <String, Map<String, double>>{};

      for (var expense in expenses) {
        final date = DateFormat('yyyy-MM-dd').parse(expense['date']);
        final month = DateFormat('MMM').format(date); // Get short month names
        final categories = List<String>.from(expense['categories']);
        final amount = expense['amount'] ?? 0.0;

        if (amount >= 0) continue; // Ignore positive amounts (income)

        final positiveAmount = amount.abs(); // Use absolute value

        // Update monthly total
        monthlyTotals[month] = (monthlyTotals[month] ?? 0.0) + positiveAmount;

        // Update category breakdown
        if (!categoryBreakdowns.containsKey(month)) {
          categoryBreakdowns[month] = {};
        }
        for (var category in categories) {
          categoryBreakdowns[month]![category] =
              (categoryBreakdowns[month]![category] ?? 0.0) + positiveAmount;
        }
      }

      setState(() {
        _monthlyTotals = monthlyTotals;
        _categoryBreakdowns = categoryBreakdowns;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  List<BarChartGroupData> _buildBarChartData() {
    final sortedKeys = _monthlyTotals.keys.toList()..sort((a, b) => a.compareTo(b));
    return sortedKeys.asMap().entries.map((entry) {
      final index = entry.key;
      final month = entry.value;
      final amount = _monthlyTotals[month]!;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: amount,
            color: Colors.blue,
            width: 20,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 0,
              color: Colors.grey.shade300,
            ),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();
  }

  List<PieChartSectionData> _buildPieChartData(String month) {
    final breakdown = _categoryBreakdowns[month];
    if (breakdown == null) return [];

    return breakdown.entries.map((entry) {
      final category = entry.key;
      final amount = entry.value;
      final percentage = (amount / _monthlyTotals[month]!) * 100;

      return PieChartSectionData(
        color: Colors.primaries[category.hashCode % Colors.primaries.length],
        value: percentage,
        title: '${category} (${percentage.toStringAsFixed(1)}%)',
        radius: 80,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Monthly Expense Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 400,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        final sortedKeys = _monthlyTotals.keys.toList()..sort();
                        return index >= 0 && index < sortedKeys.length
                            ? Text(sortedKeys[index])
                            : const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _buildBarChartData(),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Category Breakdown by Month',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ..._categoryBreakdowns.keys.map((month) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    month,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 300,
                  child: PieChart(
                    PieChartData(
                      sections: _buildPieChartData(month),
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}
