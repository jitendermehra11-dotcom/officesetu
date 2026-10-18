// lib/screens/room4_task.dart
import 'package:flutter/material.dart';

class TaskHubScreen extends StatefulWidget {
  const TaskHubScreen({Key? key}) : super(key: key);

  @override
  State<TaskHubScreen> createState() => _TaskHubScreenState();
}

class _TaskHubScreenState extends State<TaskHubScreen> {
  final List<Map<String, String>> _tasks = [
    {"title": "सुबह की शिफ्ट का अटेंडेंस मिलान", "priority": "High", "status": "Pending"},
    {"title": "मशीन नंबर 04 का मेंटेनेंस चेक", "priority": "Medium", "status": "In Progress"},
    {"title": "स्टॉक रजिस्टर का वीकली ऑडिट", "priority": "Low", "status": "Completed"},
  ];

  final TextEditingController _taskController = TextEditingController();
  String _selectedPriority = "Medium";

  void _addNewTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks.add({
          "title": _taskController.text,
          "priority": _selectedPriority,
          "status": "Pending",
        });
      });
      _taskController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('नया टास्क सफलतापूर्वक जोड़ दिया गया!')),
      );
    }
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('नया टास्क असाइन करें'),
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
              'सक्रिय टास्क सूची (Active Task List):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.deepPurple),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  bool isCompleted = task["status"] == "Completed";
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCompleted ? Colors.green[700] : Colors.deepPurple[700],
                        child: Icon(isCompleted ? Icons.check : Icons.assignment, color: Colors.white, size: 20),
                      ),
                      title: Text(
                        task["title"]!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text('प्राथमिकता: ${task["priority"]} | स्थिति: ${task["status"]}'),
                      trailing: IconButton(
                        icon: Icon(isCompleted ? Icons.undo : Icons.done, color: isCompleted ? Colors.orange : Colors.green),
                        onPressed: () {
                          setState(() {
                            _tasks[index]["status"] = isCompleted ? "Pending" : "Completed";
                          });
                        },
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
}// lib/screens/room4_task.dart
import 'package:flutter/material.dart';

class TaskHubScreen extends StatefulWidget {
  const TaskHubScreen({Key? key}) : super(key: key);

  @override
  State<TaskHubScreen> createState() => _TaskHubScreenState();
}

class _TaskHubScreenState extends State<TaskHubScreen> {
  final List<Map<String, String>> _tasks = [
    {"title": "सुबह की शिफ्ट का अटेंडेंस मिलान", "priority": "High", "status": "Pending"},
    {"title": "मशीन नंबर 04 का मेंटेनेंस चेक", "priority": "Medium", "status": "In Progress"},
    {"title": "स्टॉक रजिस्टर का वीकली ऑडिट", "priority": "Low", "status": "Completed"},
  ];

  final TextEditingController _taskController = TextEditingController();
  String _selectedPriority = "Medium";

  void _addNewTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks.add({
          "title": _taskController.text,
          "priority": _selectedPriority,
          "status": "Pending",
        });
      });
      _taskController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('नया टास्क सफलतापूर्वक जोड़ दिया गया!')),
      );
    }
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('नया टास्क असाइन करें'),
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
              'सक्रिय टास्क सूची (Active Task List):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.deepPurple),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  bool isCompleted = task["status"] == "Completed";
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCompleted ? Colors.green[700] : Colors.deepPurple[700],
                        child: Icon(isCompleted ? Icons.check : Icons.assignment, color: Colors.white, size: 20),
                      ),
                      title: Text(
                        task["title"]!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text('प्राथमिकता: ${task["priority"]} | स्थिति: ${task["status"]}'),
                      trailing: IconButton(
                        icon: Icon(isCompleted ? Icons.undo : Icons.done, color: isCompleted ? Colors.orange : Colors.green),
                        onPressed: () {
                          setState(() {
                            _tasks[index]["status"] = isCompleted ? "Pending" : "Completed";
                          });
                        },
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
