import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'LoginPage.dart';
import 'DashboardPage.dart'; // 新增
import 'ExpensesPage.dart';
import 'AddExpensePage.dart';
import 'ChartPage.dart';
import 'LedgerPage.dart';

class MyHomePage extends StatefulWidget {


  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(), // 概述信息页面
    const ExpensesPage(),
    const AddExpensePage(),
    const ChartPage(),
    const LedgerPage(),
  ];

  void _logout() async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        backgroundColor: Colors.deepPurple,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) async {
            // 如果点击 Add 页面 (index 2)
            if (index == 2) {
              final result = await Navigator.push<int>(
                context,
                MaterialPageRoute(builder: (context) => const AddExpensePage()),
              );

              // 如果返回值是 1，则切换到 Expenses 页面
              if (result == 1) {
                setState(() {
                  _currentIndex = 1; // 切换到 Expenses 页面
                });
              }
            } else {
              // 直接切换页面
              setState(() {
                _currentIndex = index;
              });
            }
          },
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Expenses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: 'Add',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart),
              label: 'Chart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: 'Ledger',
            ),
          ],
        ),
      ),
    );
  }
}
