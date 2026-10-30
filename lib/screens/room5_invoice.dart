// lib/screens/room5_invoice.dart
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:excel/excel.dart' as excel_lib;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class InvoiceGeneratorScreen extends StatefulWidget {
  const InvoiceGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceGeneratorScreen> createState() => _InvoiceGeneratorScreenState();
}

class _InvoiceGeneratorScreenState extends State<InvoiceGeneratorScreen> {
  final TextEditingController _clientController = TextEditingController(text: "Office Management Ltd.");
  final TextEditingController _itemController = TextEditingController(text: "Monthly Office Supplies & Maintenance");
  final TextEditingController _amountController = TextEditingController(text: "5000.0");
  final TextEditingController _paidAmountController = TextEditingController(text: "0.0");

  // Speech to Text (वॉइस टाइपिंग के लिए)
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  // बोलकर टेक्स्ट दर्ज करने के लिए माइक कमांड
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

  // फायरस्टोर में इनवॉइस और लेजर बैलेंस सेव करने का लाइव फंक्शन
  Future<void> _saveInvoiceToFirestore(String client, String item, double amount, double gst, double total, double paid) async {
    try {
      double pendingDues = total - paid;
      String ledgerStatus = pendingDues <= 0 ? "Fully Paid" : "Pending Dues";

      await FirebaseFirestore.instance.collection('invoices').add({
        'client': client,
        'item': item,
        'amount': amount,
        'gst': gst,
        'total': total,
        'paid': paid,
        'pendingDues': pendingDues,
        'ledgerStatus': ledgerStatus,
        'date': DateTime.now().toLocal().toString().split(' ')[0],
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Firebase Invoice Save Error: $e");
    }
  }

  // क्लाइंट-वाइज लेजर बैलेंस रीकंसीलिएशन रिपोर्ट Excel शीट में एक्सपोर्ट करने का फंक्शन
  Future<void> _exportClientLedgerToExcel() async {
    var querySnapshot = await FirebaseFirestore.instance.collection('invoices').orderBy('timestamp', descending: true).get();
    
    var excel = excel_lib.Excel.createExcel();
    String sheetName = 'Client_Ledger_Reconciliation';
    excel.rename(excel.getDefaultSheet()!, sheetName);

    excel_lib.Sheet sheetObject = excel[sheetName];
    
    // प्रोफेशनल क्लाइंट लेजर रीकंसीलिएशन हेडर
    sheetObject.appendRow([
      excel_lib.TextCellValue('Client Name'),
      excel_lib.TextCellValue('Item Description'),
      excel_lib.TextCellValue('Total Bill (₹)'),
      excel_lib.TextCellValue('Amount Paid (₹)'),
      excel_lib.TextCellValue('Pending Dues (₹)'),
      excel_lib.TextCellValue('Ledger Status'),
      excel_lib.TextCellValue('Date')
    ]);

    // डेटा रो जोड़ना
    for (var doc in querySnapshot.docs) {
      var data = doc.data();
      sheetObject.appendRow([
        excel_lib.TextCellValue(data['client'] ?? ''),
        excel_lib.TextCellValue(data['item'] ?? ''),
        excel_lib.TextCellValue(data['total'].toString()),
        excel_lib.TextCellValue((data['paid'] ?? 0.0).toString()),
        excel_lib.TextCellValue((data['pendingDues'] ?? data['total']).toString()),
        excel_lib.TextCellValue(data['ledgerStatus'] ?? 'Pending Dues'),
        excel_lib.TextCellValue(data['date'] ?? '')
      ]);
    }

    var fileBytes = excel.save();
    if (fileBytes != null) {
      await Printing.sharePdf(bytes: Uint8List.fromList(fileBytes), filename: 'officesetu_client_ledger_reconciliation.xlsx');
    }
  }

  Future<void> _generateAndPrintInvoice() async {
    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final double paid = double.tryParse(_paidAmountController.text) ?? 0.0;
    final double gst = amount * 0.18; // 18% GST calculation
    final double total = amount + gst;
    final String client = _clientController.text;
    final String item = _itemController.text;

    // फायरबेस पर लेजर रीकंसीलिएशन के साथ लाइव सेव करें
    await _saveInvoiceToFirestore(client, item, amount, gst, total, paid);

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("OfficeSetu - Official Invoice", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange)),
                pw.Text("Date: ${DateTime.now().toLocal().toString().split(' ')[0]}", style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 10),
            pw.Text("Billed To: $client", style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 15),
            pw.Text("Item Description: $item", style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.Text("Base Amount: ₹ $amount", style: const pw.TextStyle(fontSize: 14)),
            pw.Text("GST (18%): ₹ $gst", style: const pw.TextStyle(fontSize: 14)),
            pw.Divider(),
            pw.Text("Total Payable: ₹ $total", style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.Text("Amount Paid: ₹ $paid", style: const pw.TextStyle(fontSize: 14)),
            pw.Text("Pending Dues: ₹ ${total - paid}", style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
            pw.SizedBox(height: 30),
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
        title: const Text('Room 05: Invoice & Client Ledger'),
        backgroundColor: Colors.deepOrange[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _clientController,
              decoration: const InputDecoration(labelText: 'क्लाइंट / कंपनी का नाम (Gboard माइक से बोलें)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _itemController,
              decoration: const InputDecoration(labelText: 'विवरण / सेवा (Item/Service Description)'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'मूल राशि रुपये में (Amount in ₹)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _paidAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'प्राप्त भुगतान (Paid Amt in ₹)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            
            // Action Buttons (PDF इनवॉइस और क्लाइंट लेजर एक्सेल एक्सपोर्ट)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _generateAndPrintInvoice,
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('PDF इनवॉइस बनाएं'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: _exportClientLedgerToExcel,
                    icon: const Icon(Icons.table_chart, size: 18),
                    label: const Text('लेजर Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'क्लाइंट लेजर और बकाया बैलेंस (Firestore Ledger History):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepOrange),
            ),
            const SizedBox(height: 6),
            
            // StreamBuilder के जरिए क्लाइंट लेजर और पेंडिंग ड्यूज की लाइव लिस्ट दिखाना
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('invoices').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('कोई इनवॉइस या लेजर रिकॉर्ड नहीं मिला।', style: TextStyle(color: Colors.grey)));
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final client = data['client'] ?? 'क्लाइंट';
                      final total = data['total'] ?? 0.0;
                      final pending = data['pendingDues'] ?? total;
                      final status = data['ledgerStatus'] ?? 'Pending Dues';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepOrange[700],
                            child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 18),
                          ),
                          title: Text(client, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('कुल बिल: ₹$total | बकाया: ₹$pending'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: status == "Fully Paid" ? Colors.green[100] : Colors.orange[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: status == "Fully Paid" ? Colors.green[800] : Colors.orange[800],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
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
