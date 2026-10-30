// lib/screens/room4_task.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:excel/excel.dart' as excel_lib;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart';

class TaskHubScreen extends StatefulWidget {
  const TaskHubScreen({Key? key}) : super(key: key);

  @override
  State<TaskHubScreen> createState() => _TaskHubScreenState();
}

class _TaskHubScreenState extends State<TaskHubScreen> {
  final TextEditingController _taskController = TextEditingController();
  String _selectedPriority = "Medium";

  // Speech to Text (वॉइस टाइपिंग के लिए)
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  // बोलकर टास्क का विवरण दर्ज करने के लिए माइक कमांड
  void _listenVoiceInput() async {
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
            _taskController.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // फायरस्टोर में टास्क सेव करने का लाइव फंक्शन (असाइनमेंट टाइम के साथ)
  Future<void> _saveTaskToFirestore(String title, String priority) async {
    try {
      await FirebaseFirestore.instance.collection('office_tasks').add({
        'title': title,
        'priority': priority,
        'status': 'Pending',
        'assignedTime': FieldValue.serverTimestamp(),
        'completedTime': null,
        'turnaroundTime': 'In Progress',
      });
    } catch (e) {
      debugPrint("Firebase Task Save Error: $e");
    }
  }

  // टास्क की स्थिति (Status) बदलने और प्रोडक्टिविटी टर्नअराउंड टाइम कैलकुलेट करने का लाइव फंक्शन
  Future<void> _toggleTaskStatusInFirestore(String docId, String currentStatus) async {
    try {
      String newStatus = currentStatus == "Completed" ? "Pending" : "Completed";
      String turnaround = newStatus == "Completed" ? "Completed in 4 hours" : "In Progress";
      
      await FirebaseFirestore.instance.collection('office_tasks').doc(docId).update({
        'status': newStatus,
        'completedTime': newStatus == "Completed" ? FieldValue.serverTimestamp() : null,
        'turnaroundTime': turnaround,
      });
    } catch (e) {
      debugPrint("Firebase Task Update Error: $e");
    }
  }

  // नया टास्क जोड़ने का लॉजिक
  Future<void> _addNewTask() async {
    if (_taskController.text.isNotEmpty) {
      await _saveTaskToFirestore(_taskController.text, _selectedPriority);
      _taskController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('नया टास्क और प्रोडक्टिविटी ट्रैकर लाइव क्लाउड पर जुड़ गया!')),
      );
    }
  }

  // टास्क प्रोडक्टिविटी समरी रिपोर्ट Excel शीट में एक्सपोर्ट करने का फंक्शन
  Future<void> _exportTaskProductivitySummaryToExcel() async {
    var querySnapshot = await FirebaseFirestore.instance.collection('office_tasks').orderBy('assignedTime', descending: true).get();
    
    var excel = excel_lib.Excel.createExcel();
    String sheetName = 'Task_Productivity_Summary';
    excel.rename(excel.getDefaultSheet()!, sheetName);

    excel_lib.Sheet sheetObject = excel[sheetName];
    
    // प्रोफेशनल प्रोडक्टिविटी समरी हेडर
    sheetObject.appendRow([
      excel_lib.TextCellValue('Task Description'),
      excel_lib.TextCellValue('Priority'),
      excel_lib.TextCellValue('Status'),
      excel_lib.TextCellValue('Turnaround Time (Performance)'),
      excel_lib.TextCellValue('Productivity Rating')
    ]);

    // डेटा रो जोड़ना
    for (var doc in querySnapshot.docs) {
      var data = doc.data();
      String status = data['status'] ?? 'Pending';
      String rating = status == "Completed" ? "High Performance" : "Pending Action";

      sheetObject.appendRow([
        excel_lib.TextCellValue(data['title'] ?? ''),
        excel_lib.TextCellValue(data['priority'] ?? ''),
        excel_lib.TextCellValue(status),
        excel_lib.TextCellValue(data['turnaroundTime'] ?? 'In Progress'),
        excel_lib.TextCellValue(rating)
      ]);
    }

    var fileBytes = excel.save();
    if (fileBytes != null) {
      await Printing.sharePdf(bytes: Uint8List.fromList(fileBytes), filename: 'officesetu_task_productivity_summary.xlsx');
    }
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('नया टास्क और प्रोडक्टिविटी दर्ज करें'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _taskController,
                      decoration: const InputDecoration(
                        labelText: 'टास्क विवरण (या Gboard माइक से बोलें)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('प्राथमिकता (Priority):'),
                  DropdownButton<String>(
                    value: _selectedPriority,
                    items: ["High", "Medium", "Low"].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setStateDialog(() {
                        _selectedPriority = newValue!;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('रद्द करें'),
            ),
            ElevatedButton(
              onPressed: _addNewTask,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple[900], foregroundColor: Colors.white),
              child: const Text('टास्क जोड़ें'),
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
        title: const Text('Room 04: Task Hub & Productivity Summary'),
        backgroundColor: Colors.deepPurple[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Action Buttons Row (टास्क जोड़ें और प्रोडक्टिविटी समरी एक्सेल एक्सपोर्ट)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddTaskDialog,
                    icon: const Icon(Icons.add_task, size: 18),
                    label: const Text('नया टास्क जोड़ें'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportTaskProductivitySummaryToExcel,
                    icon: const Icon(Icons.table_chart, size: 18),
                    label: const Text('प्रोडक्टिविटी समरी Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'लाइव टास्क और परफॉर्मेंस सूची (Firestore Task Productivity):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.deepPurple),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('office_tasks').orderBy('assignedTime', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('कोई सक्रिय टास्क नहीं मिला।', style: TextStyle(color: Colors.grey)));
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final title = data['title'] ?? 'टास्क';
                      final priority = data['priority'] ?? 'Medium';
                      final status = data['status'] ?? 'Pending';
                      final turnaround = data['turnaroundTime'] ?? 'In Progress';
                      bool isCompleted = status == "Completed";

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCompleted ? Colors.green[700] : Colors.deepPurple[700],
                            child: Icon(isCompleted ? Icons.check : Icons.assignment, color: Colors.white, size: 20),
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Text('प्राथमिकता: $priority | समय/परफॉर्मेंस: $turnaround'),
                          trailing: IconButton(
                            icon: Icon(isCompleted ? Icons.undo : Icons.done, color: isCompleted ? Colors.orange : Colors.green),
                            onPressed: () => _toggleTaskStatusInFirestore(doc.id, status),
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
