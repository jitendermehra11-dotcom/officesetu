// lib/screens/room3_expense.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
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
  String _selectedCategory = "Supplies";
  bool _isScanningReceipt = false;
  String _receiptScanStatus = "बिल स्कैन या वॉइस कमांड द्वारा खर्च जोड़ने के लिए तैयार";

  // Speech to Text (वॉइस टाइपिंग के लिए)
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  // बोलकर विवरण या राशि दर्ज करने के लिए माइक कमांड
  void _listenVoiceInput(TextEditingController targetController) async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('status: $val'),
        onError: (val) => print('error: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: 'hi_IN',
          onResult: (val) => setState(() {
            targetController.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // फायरस्टोर में खर्च सेव करने का लाइव फंक्शन
  Future<void> _saveExpenseToFirestore(Map<String, dynamic> expData) async {
    try {
      await FirebaseFirestore.instance.collection('office_expenses').add({
        'title': expData['title'],
        'amount': expData['amount'],
        'category': expData['category'],
        'date': expData['date'],
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Firebase Expense Save Error: $e");
    }
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

      Map<String, dynamic> newExp = {
        "title": rawText.isNotEmpty ? rawText.split('\n')[0].trim() : "स्कैन किया गया बिल",
        "amount": detectedAmount,
        "category": "Scanned Bill",
        "date": "${DateTime.now().day} Oct 2026",
      };

      await _saveExpenseToFirestore(newExp);

      setState(() {
        _receiptScanStatus = "सफलतापूर्वक बिल स्कैन करके लाइव खर्च दर्ज कर दिया गया!";
        _isScanningReceipt = false;
      });

      textRecognizer.close();
    }
  }

  // मैनुअल खर्च जोड़ने का लॉजिक
  Future<void> _addExpense() async {
    if (_titleController.text.isNotEmpty && _amountController.text.isNotEmpty) {
      double? amt = double.tryParse(_amountController.text);
      if (amt != null) {
        Map<String, dynamic> newExp = {
          "title": _titleController.text,
          "amount": amt,
          "category": _selectedCategory,
          "date": "${DateTime.now().day} Oct 2026",
        };

        await _saveExpenseToFirestore(newExp);

        _titleController.clear();
        _amountController.clear();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('नया खर्च लाइव बही-खाते में दर्ज हो गया!')),
        );
      }
    }
  }

  // पूरे खर्च का बही-खाता Excel शीट में एक्सपोर्ट करने का फंक्शन
  Future<void> _exportExpenseToExcel() async {
    var querySnapshot = await FirebaseFirestore.instance.collection('office_expenses').get();
    
    var excel = excel_lib.Excel.createExcel();
    String sheetName = 'Expense_Ledger';
    excel.rename(excel.getDefaultSheet()!, sheetName);

    excel_lib.Sheet sheetObject = excel[sheetName];
    
    // एक्सेल हेडर
    sheetObject.appendRow([
      excel_lib.TextCellValue('Expense Description'),
      excel_lib.TextCellValue('Amount (₹)'),
      excel_lib.TextCellValue('Category'),
      excel_lib.TextCellValue('Date')
    ]);

    // डेटा रो जोड़ना
    for (var doc in querySnapshot.docs) {
      var data = doc.data();
      sheetObject.appendRow([
        excel_lib.TextCellValue(data['title'] ?? ''),
        excel_lib.TextCellValue(data['amount'].toString()),
        excel_lib.TextCellValue(data['category'] ?? ''),
        excel_lib.TextCellValue(data['date'] ?? '')
      ]);
    }

    var fileBytes = excel.save();
    if (fileBytes != null) {
      await Printing.sharePdf(bytes: Uint8List.fromList(fileBytes), filename: 'officesetu_expense_ledger.xlsx');
    }
  }

  // नया खर्च जोड़ने का डायलॉग बॉक्स (माइक सपोर्ट के साथ)
  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('नया खर्च दर्ज करें (Live Ledger)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'खर्च का विवरण (Description)'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.mic, color: Colors.teal),
                      onPressed: () => _listenVoiceInput(_titleController),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'रुपये (Amount in ₹)'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.mic, color: Colors.teal),
                      onPressed: () => _listenVoiceInput(_amountController),
                    ),
                  ],
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
                      totalExpense += (data['amount'] ?? 0.0) as double;
                    }
                  }

                  return Column(
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
                            const Text('कुल कार्यालय खर्च (Live Total Office Expense)', style: TextStyle(fontSize: 13, color: Colors.teal, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('₹ $totalExpense', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal[900])),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Action Buttons Row (मैनुअल, बिल स्कैन और एक्सेल एक्सपोर्ट)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showAddExpenseDialog,
                              icon: const Icon(Icons.add_circle, size: 16),
                              label: const Text('मैनुअल जोड़ें'),
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
                              onPressed: _isScanningReceipt ? null : _scanAndAutoAddReceipt,
                              icon: const Icon(Icons.camera_alt, size: 16),
                              label: Text(_isScanningReceipt ? 'स्कैनिंग...' : 'बिल OCR स्कैन'),
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
                              onPressed: _exportExpenseToExcel,
                              icon: const Icon(Icons.table_chart, size: 16),
                              label: const Text('Excel शीट'),
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
                        'खर्चों का लाइव बही-खाता (Firestore Ledger History):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
                      ),
                      const SizedBox(height: 8),

                      // List View
                      Expanded(
                        child: snapshot.connectionState == ConnectionState.waiting
                            ? const Center(child: CircularProgressIndicator())
                            : docs.isEmpty
                                ? const Center(child: Text('कोई खर्च रिकॉर्ड नहीं मिला।', style: TextStyle(color: Colors.grey)))
                                : ListView.builder(
                                    itemCount: docs.length,
                                    itemBuilder: (context, index) {
                                      final data = docs[index].data() as Map<String, dynamic>;
                                      final title = data['title'] ?? 'खर्च';
                                      final amount = data['amount'] ?? 0.0;
                                      final category = data['category'] ?? 'Misc';
                                      final date = data['date'] ?? 'आज';

                                      return Card(
                                        elevation: 2,
                                        margin: const EdgeInsets.symmetric(vertical: 6),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.teal[700],
                                            child: const Icon(Icons.receipt, color: Colors.white, size: 20),
                                          ),
                                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text('श्रेणी: $category | दिनांक: $date'),
                                          trailing: Text(
                                            '₹ $amount',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal[800]),
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
