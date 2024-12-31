import 'package:flutter/material.dart';

class LedgerPage extends StatelessWidget {
  const LedgerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Card(
          child: ListTile(
            title: const Text('Netflix Subscription'),
            subtitle: const Text('Next Payment: 2024-12-30'),
            trailing: const Text('\$15'),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Borrowed from John'),
            subtitle: const Text('Amount: \$100'),
            trailing: const Text('Payback: 2024-12-31'),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Lent to Alice'),
            subtitle: const Text('Amount: \$50'),
            trailing: const Text('Return: 2024-12-31'),
          ),
        ),
      ],
    );
  }
}
