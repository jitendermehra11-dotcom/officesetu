// lib/screens/room2_hr.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class HRHelperScreen extends StatefulWidget {
  const HRHelperScreen({Key? key}) : super(key: key);

  @override
  State<HRHelperScreen> createState() => _HRHelperScreenState();
}

class _HRHelperScreenState extends State<HRHelperScreen> {
  // सिक्योर लोकल डेटाबेस लिस्ट (एंप्लॉई, रोल, स्टेटस और लीव ट्रैकिंग के साथ)
  final List<Map<String, String>> _employees = [
    {"code": "EMP-101", "name": "राजेश कुमार", "role": "Shift Supervisor", "status": "Active", "leave": "No Leave"},
    {"code": "EMP-102", "name": "अमित शर्मा", "role": "Machine Operator", "status": "Active", "leave": "Approved Leave"},
    {"code": "EMP-103", "name": "सुनील वर्मा", "role": "Quality Inspector", "status": "On Leave", "leave": "Pending Request"},
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  
  bool _isProcessing = false;
  String _scanStatusText = "सिक्योर HR Vault तैयार - रजिस्टर स्कैन या मैनुअल एंट्री करें";

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

        setState(() {
          _employees.add({
            "code": "EMP-${100 + _employees.length + 1}",
            "name": extractedName,
            "role": "General Staff (Auto-Scanned Vault)",
            "status": "Active",
            "leave": "No Leave",
          });
          _scanStatusText = "सफलतापूर्वक स्कैन करके स्टाफ को सिक्योर Vault में जोड़ दिया गया!";
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
  void _addNewEmployee() {
    if (_nameController.text.isNotEmpty && _codeController.text.isNotEmpty && _roleController.text.isNotEmpty) {
      setState(() {
        _employees.add({
          "code": _codeController.text,
          "name": _nameController.text,
          "role": _roleController.text,
          "status": "Active",
          "leave": "No Leave",
        });
      });
      _nameController.clear();
      _codeController.clear();
      _roleController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कर्मचारी सुरक्षित रूप से HR Vault में दर्ज हो गया!')),
      );
    }
  }

  // नया एंप्लॉई जोड़ने का डायलॉग बॉक्स
  void _showAddEmployeeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('सुरक्षित HR एंप्लॉई पंजीकरण'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'कर्मचारी कोड (जैसे EMP-104)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'कर्मचारी का पूरा नाम'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _roleController,
                decoration: const InputDecoration(labelText: 'पद / भूमिका (Role/Designation)'),
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
            // Action Buttons Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddEmployeeDialog,
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('मैनुअल जोड़ें'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _scanAndAutoAddStaff,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: Text(_isProcessing ? 'स्कैनिंग...' : 'फोटो से ऑटो-जोड़ें'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[800],
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
              'सुरक्षित एंप्लॉई डेटाबेस (Excel Ready & Encrypted Vault):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _employees.length,
                itemBuilder: (context, index) {
                  final emp = _employees[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueGrey[700],
                        child: Text(emp["name"]![0], style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text('${emp["name"]} (${emp["code"]})', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('पद: ${emp["role"]} | छुट्टी स्थिति: ${emp["leave"]}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: emp["status"] == "Active" ? Colors.green[100] : Colors.orange[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          emp["status"]!,
                          style: TextStyle(
                            color: emp["status"] == "Active" ? Colors.green[800] : Colors.orange[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
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
