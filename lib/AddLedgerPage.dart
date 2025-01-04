import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';


class AddLedgerPage extends StatefulWidget {
  const AddLedgerPage({Key? key}) : super(key: key);

  @override
  _AddLedgerPageState createState() => _AddLedgerPageState();
}

class _AddLedgerPageState extends State<AddLedgerPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();

  File? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _dueDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _dueDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    setState(() {
      _isUploading = true;
    });

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_selectedImage!.path.split('/').last}';
      final ref = FirebaseStorage.instance.ref().child('ledger_images/$fileName');
      await ref.putFile(_selectedImage!);

      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _submitLedger() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    final dueDate = _dueDateController.text.trim();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (name.isEmpty || description.isEmpty || amount == null || dueDate.isEmpty || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    final imageUrl = await _uploadImage();

    final ledgerData = {
      'userId': userId,
      'name': name,
      'description': description,
      'amount': amount,
      'dueDate': DateFormat('yyyy-MM-dd').parse(dueDate),
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('ledger').add(ledgerData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ledger added successfully')),
      );

      Navigator.pop(context, true); // Return true to indicate successful submission
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add ledger: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Ledger'),
        titleTextStyle: const TextStyle(
          color: Colors.white, // 设置为白色
          fontSize: 20, // 可以根据需要调整字体大小
          fontWeight: FontWeight.bold, // 根据需要设置加粗
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(
          color: Colors.white, // 设置返回箭头为白色
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // 允许数字和小数点
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dueDateController,
              readOnly: true,
              onTap: () => _selectDueDate(context),
              decoration: const InputDecoration(
                labelText: 'Due Date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Upload Image'),
            ),
            if (_selectedImage != null)
              Image.file(
                _selectedImage!,
                height: 150,
                width: 150,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitLedger,
              child: _isUploading
                  ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
