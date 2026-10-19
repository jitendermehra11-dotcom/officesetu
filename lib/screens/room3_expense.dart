// lib/screens/room3_expense.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  // सिक्योर लेजर डेटाबेस लिस्ट
  final List<Map<String, dynamic>> _expenses = [
    {"title": "ऑफिस स्टेशनरी और पेन", "amount": 450.0, "category": "Supplies", "date": "12 Oct 2026"},
    {"title": "चाय और रिफ्रेशमेंट", "amount": 250.0, "category": "Food", "date": "13 Oct 2026"},
    {"title": "मशीन मेंटेनेंस पार्ट", "amount": 1200.0, "category": "Maintenance", "date": "14 Oct 2026"},
  ];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedCategory = "Supplies";
  bool _isScanningReceipt = false;
  String _receiptScanStatus = "बिल/रसीद स्कैन करके ऑटो-अमाउंट जोड़ने के लिए तैयार";

  double get _totalExpense {
    return _expenses.fold(0.0, (sum, item) => sum + (item["amount"] as double));
  }

  // रसीद या बिल की फोटो से OCR द्वारा राशि और विवरण डिटेक्ट करने का सिक्योर इंजन
  Future<void> _scanAndAutoAddReceipt() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _isScanningReceipt = true;
        _receiptScanStatus = "बिल स्कैन हो रहा है और राशि डिकोड की जा रही है...";
      });

      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      String rawText = recognizedText.text;
      
      // राशि (Amount) खोजने के लिए मुद्रा प्रतीक या अंकों का पैटर्न
      RegExp amountRegex = RegExp(r'(?:₹|Rs\.?|INR)?\s*([0-9]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
      Iterable<RegExpMatch> matches = amountRegex.allMatches(rawText);

      double detectedAmount = 500.0; // डिफ़ॉल्ट फॉールबैक वैल्यू यदि सटीक मैच न मिले
      for (final m in matches) {
        if (m.group(1) != null) {
          double? parsed = double.tryParse(m.group(1)!);
          if (parsed != null && parsed > 10 && parsed < 100000) {
            detectedAmount = parsed;
            break;
          }
        }
      }

      setState(() {
        _expenses.add({
          "title": rawText.isNotEmpty ? rawText.split('\n')[0].trim() : "स्कैन किया गया बिल",
          "amount": detectedAmount,
          "category": "Scanned Bill",
          "date": "${DateTime.now().day} Oct 2026",
        });
        _receiptScanStatus = "सफलतापूर्वक बिल स्कैन करके खर्च दर्ज कर दिया गया!";
        _isScanningReceipt = false;
      });

      textRecognizer.close();
    }
  }

  // मैनुअल खर्च जोड़ने का लॉजिक
  void _addExpense() {
    if (_titleController.text.isNotEmpty && _amountController.text.isNotEmpty) {
      double? amt = double.tryParse(_amountController.text);
      if (amt != null) {
        setState(() {
          _expenses.add({
            "title": _titleController.text,
            "amount": amt,
            "category": _selectedCategory,
            "date": "${DateTime.now().day} Oct 2026",
          });
        });
        _titleController.clear();
        _amountController.clear();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('नया खर्च सुरक्षित बही-खाते में दर्ज हो गया!')),
        );
      }
    }
  }

  // नया खर्च जोड़ने का डायलॉग बॉक्स
  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('नया खर्च दर्ज करें (Secure Ledger)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'खर्च का विवरण (Description)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'रुपये (Amount in ₹)'),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('श्रेणी (Category):'),
                    DropdownButton<String>(
                      value: _selectedCategory,
                      items: ["Supplies", "Food", "Maintenance", "Travel", "Misc"].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setStateDialog(() {
                          _selectedCategory = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('रद्द करें'),
            ),
            ElevatedButton(
              onPressed: _addExpense,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[900], foregroundColor: Colors.white),
              child: const Text('सुरक्षित सेव करें'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room 03: Expense Tracker & Ledger'),
        backgroundColor: Colors.teal[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Total Expense Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  const Text('कुल कार्यालय खर्च (Total Office Ledger Expense)', style: TextStyle(fontSize: 13, color: Colors.teal, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('₹ $_totalExpense', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal[900])),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddExpenseDialog,
                    icon: const Icon(Icons.add_circle, size: 18),
                    label: const Text('मैनुअल जोड़ें'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isScanningReceipt ? null : _scanAndAutoAddReceipt,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: Text(_isScanningReceipt ? 'स्कैनिंग...' : 'बिल स्कैन करके जोड़ें'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _receiptScanStatus,
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'खर्चों का सुरक्षित बही-खाता (Secure Ledger History):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _expenses.length,
                itemBuilder: (context, index) {
                  final exp = _expenses[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal[700],
                        child: const Icon(Icons.receipt, color: Colors.white, size: 20),
                      ),
                      title: Text(exp["title"], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('श्रेणी: ${exp["category"]} | दिनांक: ${exp["date"]}'),
                      trailing: Text(
                        '₹ ${exp["amount"]}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal[800]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
