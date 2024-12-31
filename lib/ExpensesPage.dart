import 'package:flutter/material.dart';

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 7, // 假设显示 7 天数据
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.all(10),
          child: ListTile(
            title: Text('Date: 2024-12-${29 - index}'),
            subtitle: const Text('Total: \$100'),
            onTap: () {
              // 跳转到详情页面
            },
          ),
        );
      },
    );
  }
}
