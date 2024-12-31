import 'ExpenseDetailPage.dart';
import 'package:flutter/material.dart';

class ExpenseDetailsPage extends StatelessWidget {
  final String date;
  final List<Map<String, dynamic>> expenses;

  const ExpenseDetailsPage({Key? key, required this.date, required this.expenses})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Details for $date'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final expense = expenses[index];
          final amount = expense['amount'];
          final summary = expense['summary'];
          final categories = (expense['categories'] as List).join(', ');

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text('\$${amount.toStringAsFixed(2)} - $summary'),
              subtitle: Text('Categories: $categories'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExpenseDetailPage(
                      expense: expense,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
