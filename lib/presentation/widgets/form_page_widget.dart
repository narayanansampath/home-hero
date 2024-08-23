import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:home_hero/presentation/widgets/directory_page_widget.dart';

class FormPageWidget extends StatefulWidget {
  const FormPageWidget({super.key});

  @override
  State<FormPageWidget> createState() => _FormPageWidgetState();
}

class _FormPageWidgetState extends State<FormPageWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  String appTitle = "";

  Future<Map<String, dynamic>> _getFormFields() async {
    DocumentSnapshot formSnapshot = await _firestore.collection('forms').doc('contactForm').get();
    return formSnapshot.data() as Map<String, dynamic>;
  }

  Future<void> _getTitle() async {
    DocumentSnapshot formSnapshot = await _firestore.collection('app_data').doc('properties').get();
    setState(() {
      appTitle = (formSnapshot.data() as Map<String, dynamic>)["app_name"];
    });
  }

  @override
  void initState() {
    super.initState();
    _getTitle();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        // Save form data to Firestore in the "form_submissions" collection
        await _firestore.collection('form_submissions').add({
          ..._formData,
          'submitted_at': FieldValue.serverTimestamp(), // Add timestamp for when the form is submitted
        });

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Form submitted successfully!')),
        );

        // Clear form data
        setState(() {
          _formData.clear();
        });
      } catch (e) {
        // Handle errors (e.g., show an error message)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting form: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appTitle),
        actions: [
        IconButton(
          icon: const Icon(Icons.list),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DirectoryPageWidget()),
            );
          },
        ),
      ],
        ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder(
                future: _getFormFields(),
                builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading form"));
                  }
            
                  List<dynamic> formFields = snapshot.data!['fields'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Form(
                      key: _formKey,
                      child: ListView.builder(
                        itemCount: formFields.length,
                        itemBuilder: (context, index) {
                          return _buildField(formFields[index]);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton(
                onPressed: _submitForm,
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(Map<String, dynamic> fieldData) {
    String label = fieldData['label'];
    String type = fieldData['type'];
    bool required = fieldData['required'] ?? false;

    switch (type) {
      case 'text':
      case 'email':
        return TextFormField(
          decoration: InputDecoration(labelText: label),
          keyboardType: type == 'email' ? TextInputType.emailAddress : TextInputType.text,
          validator: required ? (value) => value == null || value.isEmpty ? '$label is required' : null : null,
          onSaved: (value) => _formData[label] = value,
        );
      case 'textarea':
        return TextFormField(
          decoration: InputDecoration(labelText: label),
          keyboardType: TextInputType.multiline,
          maxLines: 5,
          validator: required ? (value) => value == null || value.isEmpty ? '$label is required' : null : null,
          onSaved: (value) => _formData[label] = value,
        );
      default:
        return Container();
    }
  }
}
