import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class LedgerDetailsPage extends StatefulWidget {
  final String ledgerId;

  const LedgerDetailsPage({
    Key? key,
    required this.ledgerId,
  }) : super(key: key);

  @override
  _LedgerDetailsPageState createState() => _LedgerDetailsPageState();
}

class _LedgerDetailsPageState extends State<LedgerDetailsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();

  List<String> _imageUrls = [];
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadLedgerDetails();
  }

  Future<void> _loadLedgerDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ledger')
          .doc(widget.ledgerId)
          .get();

      if (doc.exists) {
        final ledger = doc.data();
        _nameController.text = ledger?['name'] ?? '';
        _descriptionController.text = ledger?['description'] ?? '';
        _amountController.text = ledger?['amount']?.toString() ?? '';
        _dueDateController.text = ledger?['dueDate'] != null
            ? DateFormat('yyyy-MM-dd').format(ledger?['dueDate'].toDate())
            : '';
        _imageUrls = List<String>.from(ledger?['imageUrl'] ?? []);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load ledger: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);

      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        final ref = FirebaseStorage.instance.ref().child('ledger_images/$fileName');
        await ref.putFile(file);

        final downloadUrl = await ref.getDownloadURL();

        setState(() {
          _imageUrls.add(downloadUrl);
        });

        await FirebaseFirestore.instance.collection('ledger').doc(widget.ledgerId).update({
          'imageUrl': _imageUrls,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image added successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add image: $e')),
        );
      }
    }
  }

  Future<void> _deleteImage(String url) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();

      setState(() {
        _imageUrls.remove(url);
      });

      await FirebaseFirestore.instance.collection('ledger').doc(widget.ledgerId).update({
        'imageUrl': _imageUrls,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete image: $e')),
      );
    }
  }

  Future<void> _updateLedger() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    final dueDate = _dueDateController.text.trim();

    if (name.isEmpty || description.isEmpty || amount == null || dueDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await FirebaseFirestore.instance.collection('ledger').doc(widget.ledgerId).update({
        'name': name,
        'description': description,
        'amount': amount,
        'dueDate': DateFormat('yyyy-MM-dd').parse(dueDate),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ledger updated successfully')),
      );

      Navigator.pop(context, true); // Indicate successful update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update ledger: $e')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledger Details'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
              keyboardType: TextInputType.number,
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
            const SizedBox(height: 20),
            if (_imageUrls.isNotEmpty)
              Wrap(
                spacing: 8.0,
                children: _imageUrls
                    .map(
                      (url) => Stack(
                    children: [
                      Image.network(
                        url,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _deleteImage(url),
                        ),
                      ),
                    ],
                  ),
                )
                    .toList(),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addImage,
              child: const Text('Add Image'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUpdating ? null : _updateLedger,
              child: _isUpdating
                  ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
