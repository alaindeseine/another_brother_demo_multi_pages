import 'dart:io';
import 'dart:typed_data';

import 'package:another_brother/custom_paper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:another_brother/printer_info.dart' as brother;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo Brother PDF multipage',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Demo Brother PDF multipage'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  _showSnackBarErrorMessage(
      String title, String message, bool shouldGoBackAfterMessage,
      {int? duration}) {
    duration ??= 5;

    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      SnackBar(
        backgroundColor: Colors.amber,
        duration: Duration(
          seconds: duration,
        ),
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _printMultiPagePDF() async {
    // Check permissions
    if (await Permission.bluetooth.isRestricted) {
      // Display a prompt/pop-up for the user to enable bluetooth on their device
      debugPrint(
          "???????????????????? Bluetooth permission not granted ????????????????????");
    }

    if (Platform.isAndroid) {
      if (!await Permission.bluetoothScan.request().isGranted) {
        _showSnackBarErrorMessage(
          "Autorisations : ",
          "L'accès bluetooth est requis pour pouvoir imprimer.",
          false,
        );

        return null;
      }

      if (!await Permission.bluetoothConnect.request().isGranted) {
        _showSnackBarErrorMessage(
          "Autorisations : ",
          "L'accès à la connexion bluetooth est requis pour pouvoir imprimer.",
          false,
        );

        return null;
      }
    } else if (Platform.isIOS) {
      // iOS-specific code
    }

    // Configure printer
    brother.Printer printer = brother.Printer();
    brother.PrinterInfo printInfo = brother.PrinterInfo();

    printInfo.numberOfCopies = 1;
    printInfo.halftone = brother.Halftone.THRESHOLD;
    printInfo.thresholdingValue = 128;
    printInfo.printerModel = brother.Model.TD_2125NWB;
    printInfo.isAutoCut = true;
    printInfo.printMode = brother.PrintMode.FIT_TO_PAGE;
    printInfo.printQuality = brother.PrintQuality.HIGH_RESOLUTION;
    printInfo.rjDensity = 8;
    printInfo.binCustomPaper = BinPaper_TD2125NWB.W57_H51mm;

    // Find first bluetooth printer and print PDF
    printInfo.port = brother.Port.BLUETOOTH;
    await printer.setPrinterInfo(printInfo);

    List<brother.BluetoothPrinter> printers =
        await printer.getBluetoothPrinters(
      [
        brother.Model.TD_2125NWB.getName(),
      ],
    );

    debugPrint("======> Bluetooth printers: ${printers.toString()}");

    if (printers.isEmpty) {
      _showSnackBarErrorMessage(
        "Autorisations : ",
        "Aucun imprimante bluetooth trouvée.",
        false,
      );
      return;
    }

    printInfo.macAddress = printers[0].macAddress;
    await printer.setPrinterInfo(printInfo);

    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    File tempFile = File('$tempPath/copy.pdf');
    ByteData bd = await rootBundle.load('assets/labels.pdf');
    await tempFile.writeAsBytes(bd.buffer.asUint8List(), flush: true);

    brother.PrinterStatus printStatus =
        await printer.printPdfFile(tempFile.path, 1);

    debugPrint("Print results: $printStatus");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _printMultiPagePDF,
              child: const Text("    Print    "),
            ),
          ],
        ),
      ),
    );
  }
}
