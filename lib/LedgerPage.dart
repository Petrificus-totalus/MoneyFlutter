import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AddLedgerPage.dart';
import 'LedgerDetailsPage.dart';
import 'package:intl/intl.dart';

class LedgerPage extends StatefulWidget {
  const LedgerPage({Key? key}) : super(key: key);

  @override
  _LedgerPageState createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _deleteLedger(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ledger'),
        content: const Text('Are you sure you want to delete this ledger?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('ledger').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ledger deleted successfully')),
      );
    }
  }

  Future<void> _viewDetails(String id) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LedgerDetailsPage(ledgerId: id),
      ),
    );

    if (result == true) {
      setState(() {}); // Refresh the page if the ledger was edited
    }
  }


  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledger'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddLedgerPage()),
              ).then((value) {
                if (value == true) {
                  setState(() {}); // Refresh the page after adding a new ledger
                }
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('ledger')
            .where('userId', isEqualTo: userId)
            .orderBy('dueDate', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No ledger entries found.'));
          }

          final ledgers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: ledgers.length,
            itemBuilder: (context, index) {
              final ledgerDoc = ledgers[index];
              final ledger = ledgerDoc.data() as Map<String, dynamic>;
              final id = ledgerDoc.id;
              final description = ledger['description'] ?? '';
              final name = ledger['name'] ?? '';
              final amount = ledger['amount'] ?? 0.0;
              final dueDate = ledger['dueDate']?.toDate() ?? DateTime.now();

              return Dismissible(
                key: Key(id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  _deleteLedger(id);
                },
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Ledger'),
                      content: const Text(
                          'Are you sure you want to delete this ledger?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                child: Card(
                  child: ListTile(
                    title: Text(name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Due: ${DateFormat('yyyy-MM-dd').format(dueDate)}',
                        ),
                      ],
                    ),
                    trailing: Text('${amount.toStringAsFixed(2)}'),
                    onTap: () => _viewDetails(id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
