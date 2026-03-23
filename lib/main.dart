import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> users = [];

  bool scanned = false;

  Future<void> pickExcelFile() async {
    var result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      List<Map<String, dynamic>> tempUsers = [];

      for (var table in excel.tables.keys) {
        for (var row in excel.tables[table]!.rows.skip(1)) {
          tempUsers.add({
            "name": row[0]?.value.toString(),
            "code": row[1]?.value.toString(),
            "checked": false,
          });
        }
      }

      setState(() {
        users = tempUsers;
      });
    }
  }

  void checkUser(String scannedCode) {
    if (scanned) return;

    for (var user in users) {
      if (user['code'] == scannedCode) {
        setState(() {
          user['checked'] = true;
          scanned = true;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("${user['name']} تم تسجيله ✔️")));

        Future.delayed(Duration(seconds: 2), () {
          scanned = false;
        });

        return;
      }
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("الكود غير موجود ❌")));
  }

  void startScan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScanPage(onScan: checkUser)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("تسجيل الحضور"), centerTitle: true),
      body: users.isEmpty
          ? Center(child: Text("اختار ملف Excel الأول"))
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(users[index]['name']),
                  trailing: Icon(
                    users[index]['checked'] ? Icons.check_circle : Icons.cancel,
                    color: users[index]['checked'] ? Colors.green : Colors.red,
                  ),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: pickExcelFile,
            heroTag: "file",
            child: Icon(Icons.upload_file),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: startScan,
            heroTag: "scan",
            child: Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }
}

class ScanPage extends StatelessWidget {
  final Function(String) onScan;

  ScanPage({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan")),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;

          for (final barcode in barcodes) {
            final String? code = barcode.rawValue;

            if (code != null) {
              onScan(code);
              Navigator.pop(context);
              break;
            }
          }
        },
      ),
    );
  }
}
