// lib/screens/room2_hr.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:excel/excel.dart' as excel_lib;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class HRHelperScreen extends StatefulWidget {
  const HRHelperScreen({Key? key}) : super(key: key);

  @override
  State<HRHelperScreen> createState() => _HRHelperScreenState();
}

class _HRHelperScreenState extends State<HRHelperScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  
  bool _isProcessing = false;
  String _scanStatusText = "सिक्योर HR Vault तैयार - रजिस्टर स्कैन या वॉइस कमांड दें";

  // Speech to Text (वॉइस टाइपिंग के लिए)
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  // बोलकर कर्मचारी का नाम या विवरण दर्ज करने के लिए माइक कमांड
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

  // फायरस्टोर में नया कर्मचारी सेव करने का लाइव फंक्शन
  Future<void> _saveEmployeeToFirestore(Map<String, String> empData) async {
    try {
      await FirebaseFirestore.instance.collection('staff_records').add({
        'code': empData['code'],
        'name': empData['name'],
        'role': empData['role'],
        'status': empData['status'],
        'leave': empData['leave'],
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Firebase Save Error: $e");
    }
  }

  // फोटो से OCR द्वारा स्टाफ नाम और कोड डिटेक्ट करके ऑटो-जोड़ने का सुरक्षित इंजन
  Future<void> _scanAndAutoAddStaff() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _isProcessing = true;
        _scanStatusText = "सुरक्षित OCR स्कैनिंग और डेटा डिक्रिप्टिंग जारी है...";
      });

      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      String rawText = recognizedText.text;
      
      if (rawText.isNotEmpty) {
        List<String> lines = rawText.split('\n');
        String extractedName = lines.isNotEmpty ? lines[0].trim() : "स्कैन किया गया स्टाफ";

        Map<String, String> newEmp = {
          "code": "EMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
          "name": extractedName,
          "role": "General Staff (Auto-Scanned Vault)",
          "status": "Active",
          "leave": "No Leave",
        };

        // फायरबेस पर लाइव सेव करें
        await _saveEmployeeToFirestore(newEmp);

        setState(() {
          _scanStatusText = "सफलतापूर्वक स्कैन करके स्टाफ को लाइव Vault में जोड़ दिया गया!";
          _isProcessing = false;
        });
      } else {
        setState(() {
          _scanStatusText = "फोटो में कोई स्पष्ट टेक्स्ट नहीं मिला। कृपया साफ़ रोशनी में प्रयास करें।";
          _isProcessing = false;
        });
      }

      textRecognizer.close();
    }
  }

  // नया कर्मचारी सुरक्षित तरीके से जोड़ने का लॉजिक
  Future<void> _addNewEmployee() async {
    if (_nameController.text.isNotEmpty && _codeController.text.isNotEmpty && _roleController.text.isNotEmpty) {
      Map<String, String> newEmp = {
        "code": _codeController.text,
        "name": _nameController.text,
        "role": _roleController.text,
        "status": "Active",
        "leave": "No Leave",
      };

      await _saveEmployeeToFirestore(newEmp);

      _nameController.clear();
      _codeController.clear();
      _roleController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कर्मचारी लाइव HR Vault में सुरक्षित दर्ज हो गया!')),
      );
    }
  }

  // पूरा स्टाफ डेटा Excel शीट में एक्सपोर्ट करने का फंक्शन
  Future<void> _exportStaffToExcel() async {
    var querySnapshot = await FirebaseFirestore.instance.collection('staff_records').get();
    
    var excel = excel_lib.Excel.createExcel();
    String sheetName = 'HR_Staff_Vault';
    excel.rename(excel.getDefaultSheet()!, sheetName);

    excel_lib.Sheet sheetObject = excel[sheetName];
    
    // एक्सेल हेडर
    sheetObject.appendRow([
      excel_lib.TextCellValue('Employee Code'),
      excel_lib.TextCellValue('Staff Name'),
      excel_lib.TextCellValue('Role / Designation'),
      excel_lib.TextCellValue('Status'),
      excel_lib.TextCellValue('Leave Status')
    ]);

    // डेटा रो जोड़ना
    for (var doc in querySnapshot.docs) {
      var data = doc.data();
      sheetObject.appendRow([
        excel_lib.TextCellValue(data['code'] ?? ''),
        excel_lib.TextCellValue(data['name'] ?? ''),
        excel_lib.TextCellValue(data['role'] ?? ''),
        excel_lib.TextCellValue(data['status'] ?? ''),
        excel_lib.TextCellValue(data['leave'] ?? '')
      ]);
    }

    var fileBytes = excel.save();
    if (fileBytes != null) {
      await Printing.sharePdf(bytes: Uint8List.fromList(fileBytes), filename: 'officesetu_hr_staff_report.xlsx');
    }
  }

  // नया एंप्लॉई जोड़ने का डायलॉग बॉक्स (माइक सपोर्ट के साथ)
  void _showAddEmployeeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('सुरक्षित HR एंप्लॉई पंजीकरण'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(labelText: 'कर्मचारी कोड (उदा. EMP-104)'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic, color: Colors.blueGrey),
                    onPressed: () => _listenVoiceInput(_codeController),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'कर्मचारी का पूरा नाम'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic, color: Colors.blueGrey),
                    onPressed: () => _listenVoiceInput(_nameController),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _roleController,
                      decoration: const InputDecoration(labelText: 'पद / भूमिका (Designation)'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic, color: Colors.blueGrey),
                    onPressed: () => _listenVoiceInput(_roleController),
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
            onPressed: _addNewEmployee,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[900], foregroundColor: Colors.white),
            child: const Text('सुरक्षित सेव करें'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room 02: HR Helper & Secure Vault'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Action Buttons Row (मैनुअल, ऑटो-स्कैन और एक्सेल एक्सपोर्ट)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddEmployeeDialog,
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('मैनुअल जोड़ें'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _scanAndAutoAddStaff,
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: Text(_isProcessing ? 'स्कैनिंग...' : 'फोटो से OCR'),
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
                    onPressed: _exportStaffToExcel,
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
              _scanStatusText,
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'लाइव क्लाउड एंप्लॉई डेटाबेस (Firestore Vault):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey),
            ),
            const SizedBox(height: 8),
            
            // StreamBuilder के जरिए फायरस्टोर से लाइव डेटा दिखाना
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('staff_records').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('कोई स्टाफ रिकॉर्ड नहीं मिला। नया कर्मचारी जोड़ें।', style: TextStyle(color: Colors.grey)),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'अज्ञात';
                      final code = data['code'] ?? 'EMP-000';
                      final role = data['role'] ?? 'स्टाफ';
                      final status = data['status'] ?? 'Active';
                      final leave = data['leave'] ?? 'No Leave';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueGrey[700],
                            child: Text(name.isNotEmpty ? name[0] : 'E', style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text('$name ($code)', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('पद: $role | छुट्टी स्थिति: $leave'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == "Active" ? Colors.green[100] : Colors.orange[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: status == "Active" ? Colors.green[800] : Colors.orange[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
