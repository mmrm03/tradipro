import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../storage.dart';
import '../models.dart';

class AddEntryScreen extends StatefulWidget {
  final TradeEntry? entryToEdit;
  const AddEntryScreen({Key? key, this.entryToEdit}) : super(key: key);

  @override
  _AddEntryScreenState createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String? _platform;
  String? _tradeType;
  final _pairsController = TextEditingController();
  final _plController = TextEditingController();

  final platforms = ['Exness', 'Binance', 'MEXC', 'Gate.io', 'Bitget', 'Wallet', 'Other'];
  final tradeTypes = ['Spot', 'Futures', 'Forex'];

  @override
  void initState() {
    super.initState();
    if (widget.entryToEdit != null) {
      final e = widget.entryToEdit!;
      try { _selectedDate = DateFormat('dd-MM-yyyy').parse(e.date); } catch(_) {}
      _platform = platforms.contains(e.platform) ? e.platform : null;
      _tradeType = tradeTypes.contains(e.tradeType) ? e.tradeType : null;
      _pairsController.text = e.pairs;
      _plController.text = e.pl.toString();
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final dateStr = DateFormat('dd-MM-yyyy').format(_selectedDate!);
      
      final entry = TradeEntry(
        id: widget.entryToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        date: dateStr,
        platform: _platform!,
        pairs: _pairsController.text,
        tradeType: _tradeType!,
        pl: double.parse(_plController.text),
      );

      try {
        await StorageService.addEntry(entry);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        String msg = e.toString().replaceAll("Exception: ", "");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFFF43F5E), // Theme Red
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } else if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select a valid date.'),
            backgroundColor: Color(0xFFF43F5E),
            behavior: SnackBarBehavior.floating,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entryToEdit == null ? 'Add Entry' : 'Edit Entry'),
        actions: [
          if (widget.entryToEdit != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Color(0xFFF43F5E)),
              onPressed: () async {
                await StorageService.deleteEntry(widget.entryToEdit!.id);
                if (mounted) Navigator.pop(context, true);
              },
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ListTile(
                title: Text(_selectedDate == null ? 'Select Date' : DateFormat('dd-MM-yyyy').format(_selectedDate!)),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _selectedDate = d);
                },
              ),
              DropdownButtonFormField<String>(
                value: _platform,
                decoration: InputDecoration(labelText: 'Platform'),
                items: platforms.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _platform = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              TextFormField(
                controller: _pairsController,
                decoration: InputDecoration(labelText: 'Pairs (e.g. BTC/USDT)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              DropdownButtonFormField<String>(
                value: _tradeType,
                decoration: InputDecoration(labelText: 'Trade Type'),
                items: tradeTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _tradeType = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              TextFormField(
                controller: _plController,
                decoration: InputDecoration(labelText: 'Profit/Loss (\$)'),
                keyboardType: TextInputType.numberWithOptions(signed: true, decimal: true),
                validator: (v) {
                  if (v!.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Must be a number';
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: Text(widget.entryToEdit == null ? 'Add Entry' : 'Save Changes'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
