// lib/screens/room5_invoice.dart
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvoiceGeneratorScreen extends StatefulWidget {
  const InvoiceGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceGeneratorScreen> createState() => _InvoiceGeneratorScreenState();
}

class _InvoiceGeneratorScreenState extends State<InvoiceGeneratorScreen> {
  final TextEditingController _clientController = TextEditingController(text: "Office Management Ltd.");
  final TextEditingController _itemController = TextEditingController(text: "Monthly Office Supplies & Maintenance");
  final TextEditingController _amountController = TextEditingController(text: "5000.0");

  Future<void> _generateAndPrintInvoice() async {
    final pdf = pw.Document();
    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final double gst = amount * 0.18; // 18% GST calculation
    final double total = amount + gst;

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
            pw.Text("Billed To: ${_clientController.text}", style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 20),
            pw.Text("Item Description: ${_itemController.text}", style: const pw.TextStyle(fontSize: 14)),
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
            const SizedBox(height: 12),
            TextField(
              controller: _itemController,
              decoration: const InputDecoration(labelText: 'विवरण / सेवा (Item/Service Description)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'मूल राशि रुपये में (Amount in ₹)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateAndPrintInvoice,
              icon: const Icon(Icons.print, size: 20),
              label: const Text('प्रोफेशनल इनवॉइस PDF बनाएं और प्रिंट करें'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const Spacer(),
            const Text(
              'सुझाव: यह बटन सीधे एक खूबसूरत कॉर्पोरेट इनवॉइस पीडीएफ तैयार करके शेयर या प्रिंट करने का विकल्प देगा।',
              style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
