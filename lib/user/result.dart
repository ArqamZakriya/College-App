import 'dart:io';
import 'package:college_app/user/u_home.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const ResultPage());
}

class ResultPage extends StatelessWidget {
  const ResultPage({super.key});

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
  WebViewExampleState createState() => WebViewExampleState();
}

class WebViewExampleState extends State<WebViewExample> {
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
        title: const Text('Result Page'),
      ),
      body: const WebView(
        initialUrl: 'https://results.vtu.ac.in/',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
