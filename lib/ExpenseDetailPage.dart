import 'package:flutter/material.dart';

class ExpenseDetailPage extends StatelessWidget {
  final Map<String, dynamic> expense;

  const ExpenseDetailPage({Key? key, required this.expense}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final amount = expense['amount'];
    final summary = expense['summary'];
    final details = expense['details'];
    final categories = (expense['categories'] as List).join(', ');
    final images = expense['imageUrls'] as List;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ${amount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Summary: $summary'),
            const SizedBox(height: 8),
            Text('Details: $details'),
            const SizedBox(height: 8),
            Text('Categories: $categories'),
            const SizedBox(height: 16),
            Text('Images:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: images
                  .map((url) => Image.network(url, height: 100, width: 100))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // 编辑逻辑
                  },
                  child: const Text('Edit'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // 删除逻辑
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
