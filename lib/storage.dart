import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'models.dart';

class StorageService {
  static const String _settingsBox = 'settings';
  static const String _tradesBox = 'trades';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TradeEntryAdapter());
    await Hive.openBox(_settingsBox);
    await Hive.openBox<TradeEntry>(_tradesBox);
  }

  static double? get initialBalance => Hive.box(_settingsBox).get('initialBalance');

  static Future<void> setInitialBalance(double balance) async {
    await Hive.box(_settingsBox).put('initialBalance', balance);
  }

  static List<TradeEntry> getEntries() {
    final box = Hive.box<TradeEntry>(_tradesBox);
    final list = box.values.toList();
    list.sort((a, b) {
      final da = DateFormat('dd-MM-yyyy').parse(a.date);
      final db = DateFormat('dd-MM-yyyy').parse(b.date);
      return da.compareTo(db);
    });
    return list;
  }

  static Future<void> deleteEntry(String id) async {
    await Hive.box<TradeEntry>(_tradesBox).delete(id);
  }

  static Future<void> addEntry(TradeEntry entry) async {
    try {
      final box = Hive.box<TradeEntry>(_tradesBox);
      bool dateExists = box.values.any((e) => e.date == entry.date && e.id != entry.id);
      if (dateExists) {
        throw Exception('An entry for ${entry.date} already exists.');
      }
      await box.put(entry.id, entry);
    } catch (e) {
      if (e.toString().contains('already exists')) {
         rethrow;
      }
      throw Exception('Database storage error: $e');
    }
  }
  
  static Future<void> clearAll() async {
     await Hive.box<TradeEntry>(_tradesBox).clear();
     await Hive.box(_settingsBox).clear();
  }

  static List<Map<String, dynamic>> getCalculatedTable() {
    final entries = getEntries();
    double currentBalance = initialBalance ?? 0.0;
    double cumulativePl = 0.0;
    List<Map<String, dynamic>> result = [];
    
    for (int i = 0; i < entries.length; i++) {
        final e = entries[i];
        final dayNum = i + 1;
        cumulativePl += e.pl;
        
        final prevBalance = currentBalance;
        currentBalance += e.pl;
        
        final dailyPct = prevBalance == 0 ? 0.0 : (e.pl / prevBalance) * 100;
        final resStr = e.pl > 0 ? "Win" : (e.pl < 0 ? "Loss" : "Break-even");
        
        result.add({
            'entry': e,
            'dayNum': dayNum,
            'cumulativePl': cumulativePl,
            'balance': currentBalance,
            'dailyPct': dailyPct,
            'result': resStr,
        });
    }
    return result;
  }

  static Future<String?> exportToExcel() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Trades'];
      excel.setDefaultSheet('Trades');
      
      List<String> headers = ['Day #', 'Date', 'Platform', 'Pairs', 'Trade Type', 'Profit/Loss (\$)', 'Result', 'Cumulative P/L (\$)', 'Balance (\$)', 'Daily % Change'];
      sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());
      
      final table = getCalculatedTable();
      for (var row in table) {
        TradeEntry e = row['entry'];
        sheetObject.appendRow([
          IntCellValue(row['dayNum']),
          TextCellValue(e.date),
          TextCellValue(e.platform),
          TextCellValue(e.pairs),
          TextCellValue(e.tradeType),
          DoubleCellValue(e.pl),
          TextCellValue(row['result']),
          DoubleCellValue(row['cumulativePl']),
          DoubleCellValue(row['balance']),
          DoubleCellValue(row['dailyPct']),
        ]);
      }
      
      Directory? dir = await getExternalStorageDirectory();
      String path = "\${dir!.path}/trading_journal_export_\${DateFormat('dd-MM-yyyy').format(DateTime.now())}.xlsx";
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);
      return path;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> backupData() async {
    try {
      final entries = getEntries().map((e) => e.toJson()).toList();
      final data = {
        'initialBalance': initialBalance,
        'entries': entries,
      };
      Directory? dir = await getExternalStorageDirectory();
      String path = "\${dir!.path}/trading_journal_backup_\${DateFormat('dd-MM-yyyy').format(DateTime.now())}.json";
      File(path).writeAsStringSync(jsonEncode(data));
      return path;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> restoreData({required bool replace}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null) {
        File file = File(result.files.single.path!);
        String contents = await file.readAsString();
        final data = jsonDecode(contents);
        
        if (replace) {
            await clearAll();
        }
        
        if (data['initialBalance'] != null && initialBalance == null) {
            await setInitialBalance((data['initialBalance'] as num).toDouble());
        }
        
        final box = Hive.box<TradeEntry>(_tradesBox);
        for (var item in data['entries']) {
            final entry = TradeEntry.fromJson(item);
            if (!box.containsKey(entry.id)) {
                bool dateExists = box.values.any((e) => e.date == entry.date);
                if (!dateExists) {
                    await box.put(entry.id, entry);
                }
            }
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
