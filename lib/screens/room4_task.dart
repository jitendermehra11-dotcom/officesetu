// lib/screens/room4_task.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskHubScreen extends StatefulWidget {
  const TaskHubScreen({Key? key}) : super(key: key);

  @override
  State<TaskHubScreen> createState() => _TaskHubScreenState();
}

class _TaskHubScreenState extends State<TaskHubScreen> {
  final TextEditingController _taskController = TextEditingController();
  String _selectedPriority = "Medium";

  // फायरस्टोर में टास्क सेव करने का लाइव फंक्शन
  Future<void> _saveTaskToFirestore(String title, String priority) async {
    try {
      await FirebaseFirestore.instance.collection('office_tasks').add({
        'title': title,
        'priority': priority,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Firebase Task Save Error: $e");
    }
  }

  // टास्क की स्थिति (Status) बदलने का लाइव फंक्शन
  Future<void> _toggleTaskStatusInFirestore(String docId, String currentStatus) async {
    try {
      String newStatus = currentStatus == "Completed" ? "Pending" : "Completed";
      await FirebaseFirestore.instance.collection('office_tasks').doc(docId).update({
        'status': newStatus,
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
        const SnackBar(content: Text('नया टास्क लाइव क्लाउड पर जोड़ दिया गया!')),
      );
    }
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('नया टास्क असाइन करें (Live Task)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taskController,
                decoration: const InputDecoration(labelText: 'टास्क का विवरण (Task Description)'),
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
        title: const Text('Room 04: Task Hub & Management'),
        backgroundColor: Colors.deepPurple[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _showAddTaskDialog,
              icon: const Icon(Icons.add_task, size: 20),
              label: const Text('नया टास्क असाइन करें (Add Task)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'लाइव टास्क सूची (Firestore Active Task List):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.deepPurple),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('office_tasks').orderBy('timestamp', descending: true).snapshots(),
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
                          subtitle: Text('प्राथमिकता: $priority | स्थिति: $status'),
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
