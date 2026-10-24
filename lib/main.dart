// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // **Firebase इम्पोर्ट जोड़ा गया**
import 'package:officesetu/utils/app_strings.dart';
import 'package:officesetu/screens/room1_attendance.dart';
import 'package:officesetu/screens/room2_hr.dart';
import 'package:officesetu/screens/room3_expense.dart';
import 'package:officesetu/screens/room4_task.dart';
import 'package:officesetu/screens/room5_invoice.dart';

void main() async {
  // **Firebase को इनिशियलाइज करने के लिए async और binding जरूरी है**
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        title: Text(AppStrings.isEnglish ? 'OfficeSetu - License & Subscription' : 'OfficeSetu - लाइसेंस और सब्सक्रिप्शन'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppStrings.isEnglish ? "Current Plan" : "वर्तमान योजना"}: $_currentTier', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 10),
            Text(AppStrings.isEnglish ? '1. Basic Tier: Daily 5 free scans with ads.' : '1. बेसिक टियर: विज्ञापनों के साथ दैनिक 5 मुफ्त स्कैन।'),
            Text(AppStrings.isEnglish ? '2. Standard Tier: Monthly plan for small teams.' : '2. स्टैंडर्ड टियर: छोटी टीमों के लिए मासिक प्लान।'),
            Text(AppStrings.isEnglish ? '3. Enterprise Tier: 400+ employees with full security vault.' : '3. एंटरप्राइज टियर: 400+ कर्मचारियों और फुल सिक्योरिटी वॉल्ट के साथ।'),
            const SizedBox(height: 12),
            Text(AppStrings.isEnglish ? 'Activate full version for smooth office operations.' : 'अपने ऑफिस के सुचारू संचालन के लिए फुल वर्जन एक्टिवेट करें।', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.isEnglish ? 'Close' : 'बंद करें'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppStrings.isEnglish ? 'Secure payment gateway and upgrade window coming soon!' : 'सुरक्षित पेमेंट गेटवे और प्लान अपग्रेड विंडो जल्द खुलेगी!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[900], foregroundColor: Colors.white),
            child: Text(AppStrings.isEnglish ? 'Upgrade Plan' : 'प्लान अपग्रेड करें'),
          ),
        ],
      ),
    );
  }

  // उपयोगकर्ता निर्देश (User Manual) दिखाने वाला डायलॉग
  void _showUserManualDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppStrings.isEnglish ? 'OfficeSetu - User Manual' : 'OfficeSetu - उपयोगकर्ता निर्देश'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(AppStrings.isEnglish ? '• Room 01 (Attendance): Scan attendance register using OCR and match.' : '• Room 01 (Attendance): ओसीआर स्कैनर से अटेंडेंस रजिस्टर स्कैन करें और मिलान करें।'),
                const SizedBox(height: 8),
                Text(AppStrings.isEnglish ? '• Room 02 (HR Helper): Manage staff records and secure Vault.' : '• Room 02 (HR Helper): स्टाफ के रिकॉर्ड और सिक्योर Vault प्रबंधित करें।'),
                const SizedBox(height: 8),
                Text(AppStrings.isEnglish ? '• Room 03 (Expense): Record daily expenses and ledgers.' : '• Room 03 (Expense): रोजाना के खर्चों और बही-खाते का हिसाब दर्ज करें।'),
                const SizedBox(height: 8),
                Text(AppStrings.isEnglish ? '• Room 04 (Task Hub): Allocate tasks to team and track progress.' : '• Room 04 (Task Hub): टीम को टास्क अलॉट करें और प्रोग्रेस ट्रैक करें।'),
                const SizedBox(height: 8),
                Text(AppStrings.isEnglish ? '• Room 05 (Invoice): Create professional PDF bills and billing.' : '• Room 05 (Invoice): प्रोफेशनल पीडीएफ बिल और बिलिंग तैयार करें।'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppStrings.isEnglish ? 'Got it' : 'समझ गया'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.appTitle),
        backgroundColor: Colors.indigo[900],
        actions: [
          // भाषा बदलने वाला बटन (Language Toggle)
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: AppStrings.isEnglish ? 'Switch to Hindi' : 'Switch to English',
            onPressed: () {
              setState(() {
                AppStrings.isEnglish = !AppStrings.isEnglish;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppStrings.langToast)),
              );
            },
          ),
          // यूजर मैनुअल / हेल्प बटन
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showUserManualDialog(context),
            tooltip: AppStrings.isEnglish ? 'User Manual' : 'उपयोगकर्ता निर्देश',
          ),
          // सब्सक्रिप्शन और टियर स्थिति बटन
          IconButton(
            icon: const Icon(Icons.verified_user),
            onPressed: _showSubscriptionDialog,
            tooltip: AppStrings.isEnglish ? 'Subscription Tier' : 'सब्सक्रिप्शन और टियर स्थिति',
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
                  Text(AppStrings.isEnglish ? 'Welcome, Administrator (Admin)' : 'स्वागत है, व्यवस्थापक (Admin)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const SizedBox(height: 4),
                  Text('${AppStrings.isEnglish ? "Mode" : "मोड"}: $_currentTier', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text('${AppStrings.isEnglish ? "Daily scans left" : "बेसिक दैनिक स्कैन शेष"}: $_dailyScansLeft / 5', style: TextStyle(fontSize: 12, color: Colors.teal[800], fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.isEnglish ? 'Functional Rooms:' : 'ऑफिस प्रबंधन कक्ष (Functional Rooms):',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo),
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
                    AppStrings.isEnglish ? 'Room 01: Attendance' : 'Room 01: Attendance',
                    AppStrings.isEnglish ? 'Auto-Clean OCR & Matching' : 'ऑटो-क्लीन ओसीआर और मिलान',
                    Icons.how_to_reg,
                    Colors.indigo,
                    const AttendanceMatchingScreen(),
                  ),
                  _buildRoomCard(
                    context,
                    AppStrings.isEnglish ? 'Room 02: HR Helper' : 'Room 02: HR Helper',
                    AppStrings.isEnglish ? 'Staff Records & Vault' : 'स्टाफ रिकॉर्ड और सिक्योर Vault',
                    Icons.badge,
                    Colors.blueGrey,
                    const HRHelperScreen(),
                  ),
                  _buildRoomCard(
                    context,
                    AppStrings.isEnglish ? 'Room 03: Expense' : 'Room 03: Expense',
                    AppStrings.isEnglish ? 'Expense & Ledger Book' : 'खर्च और लेजर बही-खाता',
                    Icons.account_balance_wallet,
                    Colors.teal,
                    const ExpenseTrackerScreen(),
                  ),
                  _buildRoomCard(
                    context,
                    AppStrings.isEnglish ? 'Room 04: Task Hub' : 'Room 04: Task Hub',
                    AppStrings.isEnglish ? 'Tasks & Duty Management' : 'टास्क और ड्यूटी मैनेजमेंट',
                    Icons.task_alt,
                    Colors.deepPurple,
                    const TaskHubScreen(),
                  ),
                  _buildRoomCard(
                    context,
                    AppStrings.isEnglish ? 'Room 05: Invoice' : 'Room 05: Invoice',
                    AppStrings.isEnglish ? 'Professional PDF & Billing' : 'प्रोफेशनल PDF और बिलिंग',
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
