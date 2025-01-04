import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LedgerDetailsPage extends StatelessWidget {
  final Map<String, dynamic> ledger;
  final String ledgerId;

  const LedgerDetailsPage({
    Key? key,
    required this.ledger,
    required this.ledgerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledger Details'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: ${ledger['name']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Description: ${ledger['description']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Amount: \$${ledger['amount'].toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Due Date: ${DateFormat('yyyy-MM-dd').format(ledger['dueDate'].toDate())}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to an edit screen or implement inline editing
                Navigator.pop(context, true); // Return true if edited
              },
              child: const Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }
}
