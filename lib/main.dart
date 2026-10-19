// lib/main.dart
import 'package:flutter/material.dart';
import 'package:officesetu/screens/room1_attendance.dart';
import 'package:officesetu/screens/room2_hr.dart';
import 'package:officesetu/screens/room3_expense.dart';
import 'package:officesetu/screens/room4_task.dart';
import 'package:officesetu/screens/room5_invoice.dart';

void main() {
  runApp(const OfficeSetuApp());
}

class OfficeSetuApp extends StatelessWidget {
  const OfficeSetuApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OfficeSetu - Enterprise Edition',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final int _dailyScansLeft = 5;
  final String _currentTier = "Enterprise Full Power (400+ Employees)";

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OfficeSetu - लाइसेंस और सब्सक्रिप्शन'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('वर्तमान योजना: $_currentTier', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 10),
            const Text('1. बेसिक टियर: विज्ञापनों के साथ दैनिक 5 मुफ्त स्कैन।'),
            const Text('2. स्टैंडर्ड टियर: छोटी टीमों के लिए मासिक प्लान।'),
            const Text('3. एंटरप्राइज टियर: 400+ कर्मचारियों और फुल सिक्योरिटी वॉल्ट के साथ।'),
            const SizedBox(height: 12),
            const Text('अपने ऑफिस के सुचारू संचालन के लिए फुल वर्जन एक्टिवेट करें।', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('बंद करें'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('सुरक्षित पेमेंट गेटवे और प्लान अपग्रेड विंडो जल्द खुलेगी!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[900], foregroundColor: Colors.white),
            child: const Text('प्लान अपग्रेड करें'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OfficeSetu - Master Dashboard'),
        backgroundColor: Colors.indigo[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user),
            onPressed: _showSubscriptionDialog,
            tooltip: 'सब्सक्रिप्शन और टियर स्थिति',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.indigo.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('स्वागत है, व्यवस्थापक (Admin)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const SizedBox(height: 4),
                  Text('मोड: $_currentTier', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text('बेसिक दैनिक स्कैन शेष: $_dailyScansLeft / 5', style: TextStyle(fontSize: 12, color: Colors.teal[800], fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ऑफिस प्रबंधन कक्ष (Functional Rooms):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildRoomCard(
                    context,
                    'Room 01: Attendance',
                    'ऑटो-क्लीन ओसीआर और मिलान',
                    Icons.how_to_reg,
                    Colors.indigo,
                    const AttendanceMatchingScreen(),
                  ),
                  _buildRoomCard(
                    context,
                    'Room 02: HR Helper',
                    'स्टाफ रिकॉर्ड और सिक्योर Vault',
                    Icons.badge,
                    Colors.blueGrey,
                    const HRHelperScreen(),
                  ),
                  _buildRoomCard(
                    context,
                    'Room 03: Expense',
                    'खर्च और लेजर बही-खाता',
                    Icons.account_balance_wallet,
                    Colors.teal,
                    const ExpenseTrackerScreen(),
                  ),
                  _buildRoomCard(
                    context,
                    'Room 04: Task Hub',
                    'टास्क और ड्यूटी मैनेजमेंट',
                    Icons.task_alt,
                    Colors.deepPurple,
                    const TaskHubScreen(),
                  ),
                  _buildRoomCard(
                    context,
                    'Room 05: Invoice',
                    'प्रोफेशनल PDF और बिलिंग',
                    Icons.receipt_long,
                    Colors.deepOrange,
                    const InvoiceGeneratorScreen(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, String title, String subtitle, IconData icon, MaterialColor color, Widget screen) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color[800]),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color[900]), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
