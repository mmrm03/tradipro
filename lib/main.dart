import 'package:flutter/material.dart';
import 'storage.dart';
import 'screens/dashboard_screen.dart';
import 'screens/table_screen.dart';
import 'screens/add_entry_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trading Journal',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020617), // slate-950
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A), // slate-900
          foregroundColor: Color(0xFFE2E8F0), // slate-200
          elevation: 0,
          shape: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1)), // border-slate-800
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0F172A),
          selectedItemColor: Color(0xFF0EA5E9), // sky-500
          unselectedItemColor: Color(0xFF64748B), // slate-500
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF0EA5E9),
          foregroundColor: Color(0xFF020617),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E293B))),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E293B))),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF0EA5E9))),
          filled: true,
          fillColor: Color(0xFF0F172A),
          labelStyle: TextStyle(color: Color(0xFF64748B)),
        ),
      ),
      home: StorageService.initialBalance == null ? InitBalanceScreen() : MainContainer(),
    );
  }
}

class InitBalanceScreen extends StatefulWidget {
  @override
  _InitBalanceScreenState createState() => _InitBalanceScreenState();
}

class _InitBalanceScreenState extends State<InitBalanceScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome')),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Enter Initial Balance (\$)', style: TextStyle(fontSize: 20)),
            SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final val = double.tryParse(_controller.text);
                if (val != null) {
                  await StorageService.setInitialBalance(val);
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MainContainer()));
                }
              },
              child: Text('Start Journal'),
            )
          ],
        ),
      ),
    );
  }
}

class MainContainer extends StatefulWidget {
  @override
  _MainContainerState createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;
  
  final _pages = [
    TableScreen(),
    DashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddEntryScreen()));
          if (result == true) {
             setState((){}); // refresh
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
            if (i == 2) {
                _showBackupRestoreDialog(context);
            } else {
                setState(() => _currentIndex = i);
            }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.table_chart), label: 'Entries'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Backup'),
        ],
      ),
    );
  }

  void _showBackupRestoreDialog(BuildContext context) {
     showDialog(context: context, builder: (_) => AlertDialog(
         title: Text('Backup & Restore'),
         content: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
                 ListTile(
                     leading: Icon(Icons.backup),
                     title: Text('Backup Data'),
                     onTap: () async {
                         Navigator.pop(context);
                         String? path = await StorageService.backupData();
                         if (path != null && mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup saved at \$path')));
                         }
                     }
                 ),
                 ListTile(
                     leading: Icon(Icons.restore),
                     title: Text('Restore (Replace)'),
                     onTap: () async {
                         Navigator.pop(context);
                         bool ok = await StorageService.restoreData(replace: true);
                         if (ok && mounted) setState((){});
                     }
                 ),
                 ListTile(
                     leading: Icon(Icons.merge_type),
                     title: Text('Restore (Merge)'),
                     onTap: () async {
                         Navigator.pop(context);
                         bool ok = await StorageService.restoreData(replace: false);
                         if (ok && mounted) setState((){});
                     }
                 )
             ]
         )
     ));
  }
}
