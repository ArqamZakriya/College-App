import 'dart:io';
import 'package:college_app/user/u_home.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CgpaSgpaPage extends StatelessWidget {
  const CgpaSgpaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebView Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WebViewExample(),
    );
  }
}

class WebViewExample extends StatefulWidget {
  const WebViewExample({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WebViewExampleState createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  @override
  void initState() {
    super.initState();
    // Enable hybrid composition on Android.
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
        title: const Text('CGPA/SGPA - Page'),
      ),
      body: const WebView(
        initialUrl: 'https://www.vtulife.in/vtu-sgpa-cgpa-calculator/',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}

