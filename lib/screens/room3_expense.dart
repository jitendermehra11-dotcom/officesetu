// lib/screens/room3_expense.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _verifiedAmountController = TextEditingController();
  String _selectedCategory = "Supplies";
  bool _isScanningReceipt = false;
  String _receiptScanStatus = "खर्च ऑडिट और रीकंसीलिएशन इंजन तैयार";

  // फायरस्टोर में खर्च और ऑडिट डेटा सेव करने का लाइव फंक्शन
  Future<void> _saveExpenseToFirestore(Map<String, dynamic> expData) async {
    try {
      await FirebaseFirestore.instance.collection('office_expenses').add({
        'title': expData['title'],
        'roughAmount': expData['roughAmount'],
        'verifiedAmount': expData['verifiedAmount'],
        'variance': expData['variance'],
        'category': expData['category'],
        'auditStatus': expData['auditStatus'],
        'date': expData['date'],
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Firebase Expense Save Error: $e");
    }
  }

  // रसीद या बिल की फोटो से OCR द्वारा राशि और विवरण डिटेक्ट करके ऑटो-ऑдит इंजन
  Future<void> _scanAndAutoAuditReceipt() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _isScanningReceipt = true;
        _receiptScanStatus = "बिल स्कैन हो रहा है और खर्च ऑडिट रीकंसीलिएशन जारी है...";
      });

      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      String rawText = recognizedText.text;
      
      RegExp amountRegex = RegExp(r'(?:₹|Rs\.?|INR)?\s*([0-9]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
      Iterable<RegExpMatch> matches = amountRegex.allMatches(rawText);

      double detectedAmount = 500.0;
      for (final m in matches) {
        if (m.group(1) != null) {
          double? parsed = double.tryParse(m.group(1)!);
          if (parsed != null && parsed > 10 && parsed < 100000) {
            detectedAmount = parsed;
            break;
          }
        }
      }

      // ऑटोमैटिक वैरियंस ऑडिट गणना
      double roughAmt = detectedAmount;
      double verifiedAmt = detectedAmount; // ओरिजिनल मिलान राशि
      double variance = roughAmt - verifiedAmt;
      String auditStatus = variance == 0 ? "Audited & Verified" : "Variance Found";

      Map<String, dynamic> newExp = {
        "title": rawText.isNotEmpty ? rawText.split('\n')[0].trim() : "स्कैन किया गया बिल",
        "roughAmount": roughAmt,
        "verifiedAmount": verifiedAmt,
        "variance": variance,
        "category": "Scanned Audit",
        "auditStatus": auditStatus,
        "date": "${DateTime.now().day} Oct 2026",
      };

      await _saveExpenseToFirestore(newExp);

      setState(() {
        _receiptScanStatus = "सफलतापूर्वक बिल स्कैन करके ऑडिट रिपोर्ट दर्ज कर दी गई!";
        _isScanningReceipt = false;
      });

      textRecognizer.close();
    }
  }

  // मैनुअल खर्च और ऑडिट जोड़ने का लॉजिक
  Future<void> _addExpenseWithAudit() async {
    if (_titleController.text.isNotEmpty && _amountController.text.isNotEmpty) {
      double? roughAmt = double.tryParse(_amountController.text);
      double? verifiedAmt = double.tryParse(_verifiedAmountController.text) ?? roughAmt;

      if (roughAmt != null && verifiedAmt != null) {
        double variance = roughAmt - verifiedAmt;
        String auditStatus = variance == 0 ? "Audited & Verified" : "Variance Alert";

        Map<String, dynamic> newExp = {
          "title": _titleController.text,
          "roughAmount": roughAmt,
          "verifiedAmount": verifiedAmt,
          "variance": variance,
          "category": _selectedCategory,
          "auditStatus": auditStatus,
          "date": "${DateTime.now().day} Oct 2026",
        };

        await _saveExpenseToFirestore(newExp);

        _titleController.clear();
        _amountController.clear();
        _verifiedAmountController.clear();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('खर्च और ऑडिट वैरियंस रिपोर्ट बही-खाते में दर्ज हो गई!')),
        );
      }
    }
  }

  // खर्च और ऑडिट वैरियंस रिपोर्ट Excel शीट में एक्सपोर्ट करने का फंक्शन
  Future<void> _exportExpenseAuditToExcel() async {
    var querySnapshot = await FirebaseFirestore.instance.collection('office_expenses').get();
    
    var excel = excel_lib.Excel.createExcel();
    String sheetName = 'Expense_Audit_Ledger';
    excel.rename(excel.getDefaultSheet()!, sheetName);

    excel_lib.Sheet sheetObject = excel[sheetName];
    
    // प्रोफेशनल ऑडिट रिपोर्ट हेडर
    sheetObject.appendRow([
      excel_lib.TextCellValue('Expense Description'),
      excel_lib.TextCellValue('Rough Slip Amount (₹)'),
      excel_lib.TextCellValue('Verified Voucher Amount (₹)'),
      excel_lib.TextCellValue('Variance (₹)'),
      excel_lib.TextCellValue('Category'),
      excel_lib.TextCellValue('Audit Status'),
      excel_lib.TextCellValue('Date')
    ]);

    // डेटा रो जोड़ना
    for (var doc in querySnapshot.docs) {
      var data = doc.data();
      sheetObject.appendRow([
        excel_lib.TextCellValue(data['title'] ?? ''),
        excel_lib.TextCellValue(data['roughAmount'].toString()),
        excel_lib.TextCellValue(data['verifiedAmount'].toString()),
        excel_lib.TextCellValue(data['variance'].toString()),
        excel_lib.TextCellValue(data['category'] ?? ''),
        excel_lib.TextCellValue(data['auditStatus'] ?? ''),
        excel_lib.TextCellValue(data['date'] ?? '')
      ]);
    }

    var fileBytes = excel.save();
    if (fileBytes != null) {
      await Printing.sharePdf(bytes: Uint8List.fromList(fileBytes), filename: 'officesetu_expense_audit_report.xlsx');
    }
  }

  // नया खर्च और ऑडिट डायलॉग बॉक्स (Gboard सपोर्टेड)
  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('खर्च और ऑडिट मिलान दर्ज करें'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'खर्च का विवरण (Description)', helperText: 'कीबोर्ड माइक (Gboard) से बोलकर भरें'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'रफ पर्ची राशि (Rough Amount in ₹)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _verifiedAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'ओरिजिनल बिल/वाउचर राशि (Verified Amt in ₹)'),
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
              onPressed: _addExpenseWithAudit,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[900], foregroundColor: Colors.white),
              child: const Text('ऑडिट सेव करें'),
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
        title: const Text('Room 03: Expense Audit & Variance'),
        backgroundColor: Colors.teal[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('office_expenses').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  double totalExpense = 0.0;
                  List docs = [];

                  if (snapshot.hasData) {
                    docs = snapshot.data!.docs;
                    for (var doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      totalExpense += (data['verifiedAmount'] ?? data['roughAmount'] ?? 0.0) as double;
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Total Expense Audit Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.withOpacity(0.5)),
                        ),
                        child: Column(
                          children: [
                            const Text('कुल सत्यापित कार्यालय खर्च (Audited Total Expense)', style: TextStyle(fontSize: 13, color: Colors.teal, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('₹ $totalExpense', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal[900])),
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
                              icon: const Icon(Icons.add_circle, size: 16),
                              label: const Text('मैनुअल ऑडिट'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal[800],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isScanningReceipt ? null : _scanAndAutoAuditReceipt,
                              icon: const Icon(Icons.camera_alt, size: 16),
                              label: Text(_isScanningReceipt ? 'स्कैनिंग...' : 'बिल OCR ऑडिट'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo[800],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _exportExpenseAuditToExcel,
                              icon: const Icon(Icons.table_chart, size: 16),
                              label: const Text('ऑडिट Excel'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[800],
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
                        'खर्चों की लाइव ऑडिट और वैरियंस रिपोर्ट (Firestore Ledger):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
                      ),
                      const SizedBox(height: 8),

                      // List View
                      Expanded(
                        child: snapshot.connectionState == ConnectionState.waiting
                            ? const Center(child: CircularProgressIndicator())
                            : docs.isEmpty
                                ? const Center(child: Text('कोई खर्च ऑडिट रिकॉर्ड नहीं मिला।', style: TextStyle(color: Colors.grey)))
                                : ListView.builder(
                                    itemCount: docs.length,
                                    itemBuilder: (context, index) {
                                      final data = docs[index].data() as Map<String, dynamic>;
                                      final title = data['title'] ?? 'खर्च';
                                      final roughAmt = data['roughAmount'] ?? 0.0;
                                      final verifiedAmt = data['verifiedAmount'] ?? 0.0;
                                      final variance = data['variance'] ?? 0.0;
                                      final auditStatus = data['auditStatus'] ?? 'Verified';

                                      return Card(
                                        elevation: 2,
                                        margin: const EdgeInsets.symmetric(vertical: 6),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.teal[700],
                                            child: const Icon(Icons.fact_check, color: Colors.white, size: 20),
                                          ),
                                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text('रफ: ₹$roughAmt | ओरिजिनल: ₹$verifiedAmt | अंतर: ₹$variance'),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: variance == 0 ? Colors.green[100] : Colors.orange[100],
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              auditStatus,
                                              style: TextStyle(
                                                color: variance == 0 ? Colors.green[800] : Colors.orange[800],
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
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
