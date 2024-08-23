import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DirectoryPageWidget extends StatefulWidget {
  @override
  State<DirectoryPageWidget> createState() => _DirectoryPageWidgetState();
}

class _DirectoryPageWidgetState extends State<DirectoryPageWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

   Future<void> _deleteSubmission(String documentId) async {
    try {
      await _firestore.collection('form_submissions').doc(documentId).delete();
    } catch (e) {
            print('Error deleting submission: $e');
    }
  }

  Future<void> _refreshData() async {
    // In Firestore, there's no need to explicitly refresh the data
    // because StreamBuilder automatically listens for updates.
    // However, you might use this method to force a UI update or 
    // trigger other state changes as needed.
    setState(() {});
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Submission'),
          content: Text('Are you sure you want to delete this submission?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Directory")),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: StreamBuilder(
          stream: _firestore.collection('form_submissions').orderBy('submitted_at', descending: true).snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error loading submissions"));
            }
      
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("No submissions found"));
            }
      
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot submission = snapshot.data!.docs[index];
                Map<String, dynamic> data = submission.data() as Map<String, dynamic>;
      
                // Build a list of key-value pairs
                List<Widget> fieldWidgets = [];
                data.forEach((key, value) {
                  // Format the timestamp if the key is 'submitted_at'
                  if (key == 'submitted_at' && value is Timestamp) {
                    value = value.toDate().toString();
                  }
      
                  fieldWidgets.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        "$key: $value",
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                  );
                });
      
                return Dismissible(
                  key: Key(submission.id),
                  confirmDismiss: (direction) async {
                    return await _showDeleteConfirmationDialog(context);
                  },
                  onDismissed: (direction) async {
                    await _deleteSubmission(submission.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Submission deleted')),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...fieldWidgets,
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}