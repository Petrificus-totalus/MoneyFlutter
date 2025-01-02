import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ExpenseDetailsPage.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({Key? key}) : super(key: key);

  @override
  _ExpensesPageState createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final ScrollController _scrollController = ScrollController();
  final int _itemsPerPage = 10;
  bool _isLoading = false;
  List<Map<String, dynamic>> _groupedExpenses = [];
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    print(user);

    Query query = FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .limit(_itemsPerPage);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final querySnapshot = await query.get();

    if (querySnapshot.docs.isNotEmpty) {
      _lastDocument = querySnapshot.docs.last;
      final List<Map<String, dynamic>> newExpenses = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        newExpenses.add({
          'id': doc.id,
          ...data,
        });
      }

      _groupExpensesByDate(newExpenses);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _groupExpensesByDate(List<Map<String, dynamic>> expenses) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var expense in expenses) {
      final date = expense['date'];
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(expense);
    }

    for (var date in grouped.keys) {
      final totalAmount = grouped[date]!.fold(
        0.0,
            (sum, item) => sum + (item['amount'] ?? 0.0),
      );
      _groupedExpenses.add({
        'date': date,
        'totalAmount': totalAmount,
        'expenses': grouped[date],
      });
    }

    _groupedExpenses.sort((a, b) => b['date'].compareTo(a['date']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
              !_isLoading) {
            _fetchExpenses();
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _groupedExpenses.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _groupedExpenses.length) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final groupedExpense = _groupedExpenses[index];
            final date = groupedExpense['date'];
            final totalAmount = groupedExpense['totalAmount'];

            return Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                title: Text('$date'),
                subtitle: Text('${totalAmount.toStringAsFixed(2)}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExpenseDetailsPage(
                        date: date,
                        expenses: groupedExpense['expenses'],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
