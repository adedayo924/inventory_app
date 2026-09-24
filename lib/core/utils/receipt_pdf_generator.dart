import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/sale_model.dart';
import 'formatters.dart';

class ReceiptPdfGenerator {
  static Future<Uint8List> generateReceiptPdf(
    SaleModel sale, {
    required String storeName,
    String? storePhone,
    String? storeAddress,
    String? currencySymbol,
    String? receiptFooter,
    bool is58mm = false,
  }) async {
    final pdf = pw.Document();
    final symbol = currencySymbol ?? '₦';
    final pageFormat = is58mm ? PdfPageFormat.roll57 : PdfPageFormat.roll80;

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Store Header
              pw.Text(
                'JIMS RETAIL',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.green900),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                storeName.toUpperCase(),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                textAlign: pw.TextAlign.center,
              ),
              if (storeAddress != null && storeAddress.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(storeAddress, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
              ],
              if (storePhone != null && storePhone.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text('Tel: $storePhone', style: const pw.TextStyle(fontSize: 8)),
              ],
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),

              // Invoice Metadata
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Invoice:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                  pw.Text(sale.invoiceNumber, style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(Formatters.formatDateTimeFromIso(sale.createdAt), style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              if (sale.cashierName != null)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Cashier:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(sale.cashierName!, style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              if (sale.customerName != null)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Customer:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(sale.customerName!, style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Payment:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(sale.paymentMethod.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),

              // Item Columns Header
              pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('Item Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                  pw.Expanded(flex: 1, child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center)),
                  pw.Expanded(flex: 2, child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.right)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),

              // Items
              ...sale.items.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(item.productName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                          if (item.productSku.isNotEmpty)
                            pw.Text('SKU: ${item.productSku}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                    pw.Expanded(flex: 1, child: pw.Text('${item.quantity}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        Formatters.formatCurrency(item.subtotal, symbol: symbol),
                        style: const pw.TextStyle(fontSize: 8),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              )),

              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(Formatters.formatCurrency(sale.subtotal, symbol: symbol), style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              if (sale.taxAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('VAT / Tax:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(Formatters.formatCurrency(sale.taxAmount, symbol: symbol), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL DUE:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text(Formatters.formatCurrency(sale.total, symbol: symbol), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Amount Tendered:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(Formatters.formatCurrency(sale.paid, symbol: symbol), style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Change Given:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                  pw.Text(Formatters.formatCurrency(sale.change, symbol: symbol), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                ],
              ),

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 6),

              // Footer Message & Barcode
              pw.Text(
                receiptFooter ?? 'Thank you for shopping at Jeilo! Goods sold in good condition.',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 6),
              pw.BarcodeWidget(
                barcode: pw.Barcode.code128(),
                data: sale.invoiceNumber,
                width: 130,
                height: 35,
                drawText: false,
              ),
              pw.SizedBox(height: 2),
              pw.Text(sale.invoiceNumber, style: const pw.TextStyle(fontSize: 7)),
              pw.SizedBox(height: 4),
              pw.Text('Powered by JIMS', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printReceipt(
    SaleModel sale, {
    required String storeName,
    String? storePhone,
    String? storeAddress,
    String? currencySymbol,
    String? receiptFooter,
    bool is58mm = false,
  }) async {
    final pdfBytes = await generateReceiptPdf(
      sale,
      storeName: storeName,
      storePhone: storePhone,
      storeAddress: storeAddress,
      currencySymbol: currencySymbol,
      receiptFooter: receiptFooter,
      is58mm: is58mm,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Receipt_${sale.invoiceNumber}.pdf',
    );
  }
}
