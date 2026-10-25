// lib/screens/room5_invoice.dart
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceGeneratorScreen extends StatefulWidget {
  const InvoiceGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceGeneratorScreen> createState() => _InvoiceGeneratorScreenState();
}

class _InvoiceGeneratorScreenState extends State<InvoiceGeneratorScreen> {
  final TextEditingController _clientController = TextEditingController(text: "Office Management Ltd.");
  final TextEditingController _itemController = TextEditingController(text: "Monthly Office Supplies & Maintenance");
  final TextEditingController _amountController = TextEditingController(text: "5000.0");

  // फायरस्टोर में इनवॉइस सेव करने का लाइव फंक्शन
  Future<void> _saveInvoiceToFirestore(String client, String item, double amount, double gst, double total) async {
    try {
      await FirebaseFirestore.instance.collection('invoices').add({
        'client': client,
        'item': item,
        'amount': amount,
        'gst': gst,
        'total': total,
        'date': DateTime.now().toLocal().toString().split(' ')[0],
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Firebase Invoice Save Error: $e");
    }
  }

  Future<void> _generateAndPrintInvoice() async {
    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final double gst = amount * 0.18; // 18% GST calculation
    final double total = amount + gst;
    final String client = _clientController.text;
    final String item = _itemController.text;

    // फायरबेस पर लाइव सेव करें
    await _saveInvoiceToFirestore(client, item, amount, gst, total);

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("OfficeSetu - Official Invoice", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
                pw.Text("Date: ${DateTime.now().toLocal().toString().split(' ')[0]}", style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 10),
            pw.Text("Billed To: $client", style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 20),
            pw.Text("Item Description: $item", style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.Text("Base Amount: ₹ $amount", style: const pw.TextStyle(fontSize: 14)),
            pw.Text("GST (18%): ₹ $gst", style: const pw.TextStyle(fontSize: 14)),
            pw.Divider(),
            pw.Text("Total Payable: ₹ $total", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 40),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text("Authorized Signatory\nOfficeSetu Enterprise", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room 05: Invoice & PDF Generator'),
        backgroundColor: Colors.deepOrange[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _clientController,
              decoration: const InputDecoration(labelText: 'क्लाइंट / कंपनी का नाम (Client Name)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _itemController,
              decoration: const InputDecoration(labelText: 'विवरण / सेवा (Item/Service Description)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'मूल राशि रुपये में (Amount in ₹)'),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _generateAndPrintInvoice,
              icon: const Icon(Icons.print, size: 20),
              label: const Text('प्रोफेशनल इनवॉइस बनाएं और क्लाउड सिंक करें'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'हाल के लाइव इनवॉइस (Firestore Invoice History):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepOrange),
            ),
            const SizedBox(height: 6),
            // StreamBuilder के जरिए पिछले इनवॉइस की लाइव लिस्ट दिखाना
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('invoices').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('कोई इनवॉइस रिकॉर्ड नहीं मिला।', style: TextStyle(color: Colors.grey)));
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final client = data['client'] ?? 'क्लाइंट';
                      final total = data['total'] ?? 0.0;
                      final date = data['date'] ?? 'आज';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepOrange[700],
                            child: const Icon(Icons.description, color: Colors.white, size: 18),
                          ),
                          title: Text(client, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('दिनांक: $date'),
                          trailing: Text(
                            '₹ $total',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.deepOrange[800]),
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
