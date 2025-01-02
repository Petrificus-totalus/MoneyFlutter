import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'ExpensesPage.dart';



class AddExpensePage extends StatefulWidget {
  const AddExpensePage({Key? key}) : super(key: key);

  @override
  _AddExpensePageState createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  List<String> _selectedCategories = [];
  final List<String> _categories = [
    'Food',
    'Eat Out',
    'Gas',
    'Cloth',
    'Entertainment',
    'Other',
  ];

  List<File> _selectedImages = [];
  bool _isUploading = false;
  bool _isIncome = false; // 默认选项为支出


  @override
  void initState() {
    super.initState();
    // 设置默认日期为今天
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];

    setState(() {
      _isUploading = true;
    });

    List<String> imageUrls = [];
    try {
      for (var image in _selectedImages) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
        final ref = FirebaseStorage.instance.ref().child('expense_images/$fileName');
        await ref.putFile(image);

        final downloadUrl = await ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload images: $e")),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }

    return imageUrls;
  }

  Future<void> _submitForm() async {
    final String date = _dateController.text.trim();
    final String amount = _amountController.text.trim();
    final String location = _locationController.text.trim();
    final String summary = _summaryController.text.trim();
    final String details = _detailsController.text.trim();
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (double.tryParse(amount) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in!")),
      );
      return;
    }

    if (date.isEmpty || amount.isEmpty || location.isEmpty || summary.isEmpty || _selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill out all required fields")),
      );
      return;
    }

    final imageUrls = await _uploadImages();

    if (_isUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Images are still uploading")),
      );
      return;
    }

    // 将金额转换为正负值
    final double finalAmount = _isIncome
        ? double.parse(amount) // 收入保持正值
        : -double.parse(amount); // 支出转换为负值

    print(finalAmount);
    final expenseData = {
      'userId': currentUser.uid,
      'date': date,
      'amount': finalAmount,
      'location': location,
      'categories': _selectedCategories,
      'summary': summary,
      'details': details,
      'imageUrls': imageUrls,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('expenses').add(expenseData);

      // 提示添加成功
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Expense added successfully")),
      );

      // 返回导航栏中 Expenses 的索引
      Navigator.pop(context, 1);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add expense: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 日期选择器
              TextField(
                controller: _dateController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: const InputDecoration(
                  labelText: 'Date',
                  hintText: 'YYYY-MM-DD',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Expense'),
                      value: false,
                      groupValue: _isIncome,
                      onChanged: (value) {
                        setState(() {
                          _isIncome = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Income'),
                      value: true,
                      groupValue: _isIncome,
                      onChanged: (value) {
                        setState(() {
                          _isIncome = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              // 金额输入
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Enter amount',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // 允许数字和小数点
                ],
              ),
              const SizedBox(height: 16),
              // 位置输入
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                ),
              ),
              const SizedBox(height: 16),
              // 分类多选下拉框
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Categories',
                  hintText: 'Select categories',
                ),
                items: _categories
                    .map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                ))
                    .toList(),
                onChanged: (value) {
                  if (value != null && !_selectedCategories.contains(value)) {
                    setState(() {
                      _selectedCategories.add(value);
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: _selectedCategories
                    .map((category) => Chip(
                  label: Text(category),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () {
                    setState(() {
                      _selectedCategories.remove(category);
                    });
                  },
                ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              // 简介输入
              TextField(
                controller: _summaryController,
                decoration: const InputDecoration(
                  labelText: 'Summary',
                ),
              ),
              const SizedBox(height: 16),
              // 详细信息输入
              TextField(
                controller: _detailsController,
                decoration: const InputDecoration(
                  labelText: 'Details',
                ),
              ),
              const SizedBox(height: 20),
              // 上传图片按钮
              ElevatedButton(
                onPressed: _pickImages,
                child: Text(_selectedImages.isEmpty ? 'Upload Photos' : 'Change Photos'),
              ),
              if (_selectedImages.isNotEmpty)
                Wrap(
                  spacing: 8.0,
                  children: _selectedImages
                      .map((image) => Image.file(image, height: 100, width: 100, fit: BoxFit.cover))
                      .toList(),
                ),
              if (_isUploading) const CircularProgressIndicator(),
              const SizedBox(height: 20),
              // 提交按钮
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
