import 'package:college_app/user/cgpa.dart';
import 'package:college_app/user/result.dart';
import 'package:college_app/user/u_home.dart';
import 'package:college_app/user/u_notes/select_branch.dart';
import 'package:college_app/user/u_time_table/select_branch_page.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:college_app/login.dart';
import 'package:logger/logger.dart';

void main() {
  runApp(const VoicePage());
}

class VoicePage extends StatelessWidget {
  const VoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

// Making MyHomePageState public by removing the underscore
class MyHomePageState extends State<MyHomePage> {
  var textSpeech = "CLICK ON MIC TO RECORD";
  SpeechToText speechToText = SpeechToText();
  var isListening = false;
  var logger = Logger();

  void checkMic() async {
    bool micAvailable = await speechToText.initialize(
      onError: (error) => logger.e('Failed to initialize: $error'),
      onStatus: (status) => logger.i('Speech recognition status: $status'),
    );

    if (micAvailable) {
      logger.i("Microphone Available");
    } else {
      logger.w("User Denied the use of speech microphone");
    }
  }

  @override
  void initState() {
    super.initState();
    checkMic();
  }

  void navigateToPage(String textSpeech) {
    textSpeech = textSpeech.toLowerCase();
    logger.i("Recognized text: $textSpeech");

    if (textSpeech.contains('notes')) {
      logger.i("Navigating to NotesPage");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SelectBranch()),
      );
    } else if (textSpeech.contains('timetable') ||
        textSpeech.contains('time table')) {
      logger.i("Navigating to TimeTablePage");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SelectBranchPage()),
      );
    } else if (textSpeech.contains('results') ||
        textSpeech.contains('resultpage') ||
        textSpeech.contains('result')) {
      logger.i("Navigating to ResultPage");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ResultPage()),
      );
    } else if (textSpeech.contains('cgpa calculator') ||
        textSpeech.contains('cgpa') ||
        textSpeech.contains('sgpa')||
        textSpeech.contains('sgpa calculator') ||
        textSpeech.contains('cgpa sgpa')||
        textSpeech.contains('sgpa cgpa')){
      logger.i("Navigating to CgpaSgpaPage");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CgpaSgpaPage()),
      );
    } else if (textSpeech.contains('log out') ||
         textSpeech.contains('logout')){
      logger.i("Logging out");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      logger.w('No matching page for the keyword: $textSpeech');
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
        title: const Text('Voice Page'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                textSpeech,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  if (!isListening) {
                    bool micAvailable = await speechToText.initialize();

                    if (micAvailable) {
                      setState(() {
                        isListening = true;
                      });

                      speechToText.listen(
                        listenFor: const Duration(seconds: 20),
                        onResult: (result) {
                          setState(() {
                            textSpeech = result.recognizedWords;
                            isListening = false;
                          });

                          logger.i("Detected words: ${result.recognizedWords}");
                          navigateToPage(textSpeech);
                        },
                      );
                    }
                  } else {
                    setState(() {
                      isListening = false;
                      speechToText.stop();
                    });
                  }
                },
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: isListening ? Colors.red : Colors.blue,
                  child: Icon(
                    isListening ? Icons.mic_off : Icons.mic,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Updated MyHomePage to match the public state class name
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}
