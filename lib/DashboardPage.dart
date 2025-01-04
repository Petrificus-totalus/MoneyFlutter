import 'package:flutter/material.dart';
import 'LoginPage.dart';
import 'package:firebase_auth/firebase_auth.dart';


class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 模拟数据
    final int daysTracked = 30; // 假设用户已记账 30 天
    final double totalExpense = 1250.75; // 总支出
    final double totalIncome = 1500.00; // 总收入

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Days Tracked: $daysTracked',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Total Expense: \$${totalExpense.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Total Income: \$${totalIncome.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Keep up the great work! 🎉',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          // Logout 按钮
          ElevatedButton(
            onPressed: () => _logout(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple, // 按钮背景颜色
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
