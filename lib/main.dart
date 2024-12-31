import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'LoginPage.dart';
import 'MyHomePage.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // 检查用户是否登录
      home: _checkUserLoggedIn(),
    );
  }

  Widget _checkUserLoggedIn() {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // 用户已登录，跳转到首页
      return MyHomePage(title: 'Welcome!');
    } else {
      // 用户未登录，跳转到登录页面
      return const LoginPage();
    }
  }
}
