import 'package:flutter/material.dart';
import '../storage.dart';
import 'add_entry_screen.dart';

class TableScreen extends StatefulWidget {
  @override
  _TableScreenState createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  String _selectedPlatform = 'All';
  String _selectedTradeType = 'All';

  @override
  Widget build(BuildContext context) {
    var rawTable = StorageService.getCalculatedTable();
    var table = rawTable.where((row) {
        final e = row['entry'];
        if (_selectedPlatform != 'All' && e.platform != _selectedPlatform) return false;
        if (_selectedTradeType != 'All' && e.tradeType != _selectedTradeType) return false;
        return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Data Table'),
        actions: [
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: () async {
              String? path = await StorageService.exportToExcel();
              if (path != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to: \$path')));
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
            Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                    children: [
                        Expanded(child: DropdownButtonFormField<String>(
                            value: _selectedPlatform,
                            decoration: InputDecoration(isDense: true, labelText: 'Platform'),
                            items: ['All', 'Exness', 'Binance', 'MEXC', 'Gate.io', 'Bitget', 'Wallet', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (val) => setState(() => _selectedPlatform = val!),
                        )),
                        SizedBox(width: 8),
                        Expanded(child: DropdownButtonFormField<String>(
                            value: _selectedTradeType,
                            decoration: InputDecoration(isDense: true, labelText: 'Type'),
                            items: ['All', 'Spot', 'Futures', 'Forex'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (val) => setState(() => _selectedTradeType = val!),
                        )),
                    ]
                )
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowColor: MaterialStateProperty.all(const Color(0xFF0F172A)),
                    border: const TableBorder(horizontalInside: BorderSide(color: Color(0xFF1E293B))),
                    columns: [
                      DataColumn(label: _header('Day #')),
                      DataColumn(label: _header('Date')),
                      DataColumn(label: _header('Platform')),
                      DataColumn(label: _header('Pairs')),
                      DataColumn(label: _header('Type')),
                      DataColumn(label: _header('P/L (\$)' )),
                      DataColumn(label: _header('Result')),
                      DataColumn(label: _header('Cum. P/L (\$)' )),
                      DataColumn(label: _header('Balance (\$)' )),
                      DataColumn(label: _header('Daily %')),
                    ],
                    rows: table.map((row) {
                      final e = row['entry'];
                      return DataRow(
                        onSelectChanged: (selected) async {
                          if (selected == true) {
                            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddEntryScreen(entryToEdit: e)));
                            if (result == true && mounted) setState((){});
                          }
                        },
                        cells: [
                          DataCell(Text(row['dayNum'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF94A3B8)))),
                          DataCell(Text(e.date, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFE2E8F0)))),
                          DataCell(Text(e.platform, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFE2E8F0)))),
                          DataCell(Text(e.pairs, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'monospace', color: Color(0xFFE2E8F0)))),
                          DataCell(Text(e.tradeType, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFE2E8F0)))),
                          DataCell(Text(e.pl.toStringAsFixed(2), textAlign: TextAlign.center, style: TextStyle(fontFamily: 'monospace', color: e.pl >= 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E)))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: e.pl > 0 ? const Color(0x1A10B981) : (e.pl < 0 ? const Color(0x1AF43F5E) : const Color(0xFF334155)),
                                border: Border.all(color: e.pl > 0 ? const Color(0x3310B981) : (e.pl < 0 ? const Color(0x33F43F5E) : Colors.transparent)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(row['result'].toString().toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: e.pl > 0 ? const Color(0xFF10B981) : (e.pl < 0 ? const Color(0xFFF43F5E) : const Color(0xFF94A3B8)))),
                            )
                          ),
                          DataCell(Text('\$'+(row['cumulativePl'] as double).toStringAsFixed(2), textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'monospace', color: Color(0xFFE2E8F0)))),
                          DataCell(Text('\$'+(row['balance'] as double).toStringAsFixed(2), textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'monospace', color: Color(0xFFE2E8F0)))),
                          DataCell(Text((row['dailyPct'] as double).toStringAsFixed(2) + '%', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'monospace', color: e.pl > 0 ? const Color(0xFF10B981) : (e.pl < 0 ? const Color(0xFFF43F5E) : const Color(0xFFE2E8F0))))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _header(String text) => Center(child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 1.0, color: Color(0xFF64748B), fontWeight: FontWeight.bold)));
}
