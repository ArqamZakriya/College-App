import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddCollegePage extends StatefulWidget {
  const AddCollegePage({super.key});

  @override
  _AddCollegePageState createState() => _AddCollegePageState();
}

class _AddCollegePageState extends State<AddCollegePage> {
  final TextEditingController _collegeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  List<QueryDocumentSnapshot> _filteredColleges = [];

  Future<void> _addCollege() async {
    if (_collegeController.text.isEmpty) {
      _showSnackBar('College name cannot be empty');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestore.collection('colleges').add({
        'name': _collegeController.text,
      });
      _showSnackBar('College added successfully!');
      _collegeController.clear(); // Clear the input field
    } catch (e) {
      _showSnackBar('Failed to add college: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCollege(String collegeId) async {
    try {
      await _firestore.collection('colleges').doc(collegeId).delete();
      _showSnackBar('College deleted successfully!');
    } catch (e) {
      _showSnackBar('Failed to delete college: $e');
    }
  }

  void _searchCollege(String query) {
    setState(() {
      // Clear the filtered colleges list if the search query is empty
      if (query.isEmpty) {
        _filteredColleges = [];
      } else {
        // Filter the colleges based on the search query
        _filteredColleges = _filteredColleges
            .where((college) =>
                (college.data() as Map<String, dynamic>)['name']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add College'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _collegeController,
              decoration: const InputDecoration(
                labelText: 'College Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addCollege,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text(
                        'Add College',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Search Colleges:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search College',
                border: OutlineInputBorder(),
              ),
              onChanged: _searchCollege,
            ),
            const SizedBox(height: 20),
            const Text(
              'Available Colleges:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('colleges').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading colleges'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No colleges added yet.'));
                  }

                  final colleges = snapshot.data!.docs;

                  // Store all colleges initially
                  if (_filteredColleges.isEmpty) {
                    _filteredColleges = colleges;
                  }

                  return ListView.builder(
                    itemCount: _filteredColleges.length,
                    itemBuilder: (context, index) {
                      final college = _filteredColleges[index].data() as Map<String, dynamic>;
                      final collegeId = _filteredColleges[index].id;
                      return ListTile(
                        title: Text(college['name']),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteCollege(collegeId);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
