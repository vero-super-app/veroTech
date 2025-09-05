import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import to format the date


class BecomeSellerWidget extends StatelessWidget {
  const BecomeSellerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 40,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              "Become a merchant",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You can also sell on our app. Join us and start selling your products easily.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to ApplyNowPage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ApplyNowPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Button background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Apply Now"),
            ),
          ],
        ),
      ),
    );
  }
}

class BecomeDriverWidget extends StatelessWidget {
  const BecomeDriverWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 40,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              "Become a Driver",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Join our network as a driver and start earning by delivering with us.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to ApplyNowPage
              //  Navigator.push(
                 // context,
                 // MaterialPageRoute(builder: (context) => DriverApplyNowPage()),
               // );
              },
              child: const Text("Apply Now"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//applay now page starts here



class ApplyNowPage extends StatefulWidget {
  @override
  _ApplyNowPageState createState() => _ApplyNowPageState();
}

class _ApplyNowPageState extends State<ApplyNowPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _businessDescriptionController = TextEditingController();

  bool _termsAccepted = false;

  Future<void> _submitApplication() async {
    final url = Uri.parse('http://127.0.0.1:3000/sellers/create'); // Replace with your API endpoint

    // NationalID is a string (no conversion needed)
    final nationalId = _nationalIdController.text;

    // Get the current date in ISO 8601 format
    final currentDate = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());

    // Create request body
    final body = json.encode({
      'FirstName': _firstNameController.text,
      'Surname': _surnameController.text,
      'NationalID': nationalId,
      'BusinessName': _businessNameController.text,
      'PhoneNumber': _phoneNumberController.text,
      'Address': _addressController.text,
      'BusinessDescription': _businessDescriptionController.text,
      'ApplicationDate': currentDate,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showToast('Application submitted successfully!');
        _clearForm();
      } else {
        _showToast('Failed to submit application: ${response.body}');
      }
    } catch (error) {
      _showToast('An error occurred: $error');
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _firstNameController.clear();
    _surnameController.clear();
    _nationalIdController.clear();
    _businessNameController.clear();
    _phoneNumberController.clear();
    _addressController.clear();
    _businessDescriptionController.clear();
    setState(() {
      _termsAccepted = false;
    });
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Seller'),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First Name
              _buildTextField(
                controller: _firstNameController,
                label: 'First Name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Surname
              _buildTextField(
                controller: _surnameController,
                label: 'Surname',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your surname';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // National ID
              _buildTextField(
                controller: _nationalIdController,
                label: 'National ID',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your National ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Business Name
              _buildTextField(
                controller: _businessNameController,
                label: 'Business Name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your Business Name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Phone Number
              _buildTextField(
                controller: _phoneNumberController,
                label: 'Phone Number',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Address
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Business Description
              _buildTextField(
                controller: _businessDescriptionController,
                label: 'Business Description',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please describe your business';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Accept Terms and Conditions
              Row(
                children: [
                  Checkbox(
                    value: _termsAccepted,
                    onChanged: (value) {
                      setState(() {
                        _termsAccepted = value!;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'I accept the terms and conditions',
                      style: TextStyle(fontSize: 14.0),
                    ),
                  ),
                ],
              ),
              if (!_termsAccepted)
                const Text(
                  'You must accept the terms and conditions',
                  style: TextStyle(color: Colors.red, fontSize: 12.0),
                ),
              const SizedBox(height: 16.0),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() && _termsAccepted) {
                      _submitApplication();
                    } else if (!_termsAccepted) {
                      _showToast('You must accept the terms and conditions');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit Application',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
      validator: validator,
    );
  }
}


// drivers form

// class DriverApplyNowPage extends StatefulWidget {
//   @override
//   _DriverApplyNowPageState createState() => _DriverApplyNowPageState();
// }



// class _DriverApplyNowPageState extends State<DriverApplyNowPage> {
//   final _formKey = GlobalKey<FormState>();

//   // Controllers for form fields
//   final TextEditingController _firstNameController = TextEditingController();
//   final TextEditingController _surnameController = TextEditingController();
//   final TextEditingController _registrationNumberController = TextEditingController();
//   final TextEditingController _nationalIdController = TextEditingController();
//   final TextEditingController _driverLicenseNumberController = TextEditingController();
//   final TextEditingController _phoneNumberController = TextEditingController();
//   final TextEditingController _addressController = TextEditingController();
//   final TextEditingController _businessDescriptionController = TextEditingController();

//   File? _carImage;
//   bool _termsAccepted = false;

//   Future<void> _pickImage(ImageSource source) async {
//     final pickedFile = await ImagePicker().pickImage(source: source);
//     if (pickedFile != null) {
//       setState(() {
//         _carImage = File(pickedFile.path);
//       });
//     }
//   }

//   Future<void> _submitApplication() async {
//     final url = Uri.parse('https://your-api-endpoint.com/applications'); // Replace with your API endpoint

//     final body = {
//       'firstName': _firstNameController.text,
//       'surname': _surnameController.text,
//       'nationalId': _nationalIdController.text,
//       'registrationNumber': _registrationNumberController.text,
//       'driverLicenseNumber': _driverLicenseNumberController.text,
//       'phoneNumber': _phoneNumberController.text,
//       'address': _addressController.text,
//       'businessDescription': _businessDescriptionController.text,
//     };

//     try {
//       final request = http.MultipartRequest('POST', url);
//       body.forEach((key, value) {
//         request.fields[key] = value;
//       });

//       if (_carImage != null) {
//         request.files.add(
//           await http.MultipartFile.fromPath('carImage', _carImage!.path),
//         );
//       }

//       final response = await request.send();

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         _showToast('Application submitted successfully!');
//         _clearForm();
//       } else {
//         _showToast('Failed to submit application: ${response.reasonPhrase}');
//       }
//     } catch (error) {
//       _showToast('An error occurred: $error');
//     }
//   }

//   void _clearForm() {
//     _formKey.currentState?.reset();
//     _firstNameController.clear();
//     _surnameController.clear();
//     _registrationNumberController.clear();
//     _nationalIdController.clear();
//     _driverLicenseNumberController.clear();
//     _phoneNumberController.clear();
//     _addressController.clear();
//     _businessDescriptionController.clear();
//     setState(() {
//       _carImage = null;
//       _termsAccepted = false;
//     });
//   }

//   void _showToast(String message) {
//     Fluttertoast.showToast(
//       msg: message,
//       toastLength: Toast.LENGTH_LONG,
//       gravity: ToastGravity.CENTER,
//       backgroundColor: Colors.green,
//       textColor: Colors.white,
//       fontSize: 16.0,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Become a Driver'),
//         centerTitle: true,
//         backgroundColor: Colors.orange,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // First Name
//               _buildTextField(
//                 controller: _firstNameController,
//                 label: 'First Name',
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your first name';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16.0),

//               // Surname
//               _buildTextField(
//                 controller: _surnameController,
//                 label: 'Surname',
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your surname';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16.0),

//               // National ID
//               _buildTextField(
//                 controller: _nationalIdController,
//                 label: 'National ID',
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your National ID';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16.0),

//               // Registration Number
//               _buildTextField(
//                 controller: _registrationNumberController,
//                 label: 'Registration Number',
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter the vehicle registration number';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16.0),

//               // Driver License Number
//               _buildTextField(
//                 controller: _driverLicenseNumberController,
//                 label: 'Driver License Number',
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your driver license number';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16.0),

//               // Upload Car Image
//               Row(
//                 children: [
//                   ElevatedButton.icon(
//                     onPressed: () => _pickImage(ImageSource.camera),
//                     icon: const Icon(Icons.camera_alt),
//                     label: const Text('Camera'),
//                   ),
//                   const SizedBox(width: 8.0),
//                   ElevatedButton.icon(
//                     onPressed: () => _pickImage(ImageSource.gallery),
//                     icon: const Icon(Icons.photo_library),
//                     label: const Text('Gallery'),
//                   ),
//                 ],
//               ),
//               if (_carImage != null)
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 16.0),
//                   child: Image.file(
//                     _carImage!,
//                     width: 200,
//                     height: 200,
//                   ),
//                 ),
//               const SizedBox(height: 16.0),

//               // Accept Terms and Conditions
//               Row(
//                 children: [
//                   Checkbox(
//                     value: _termsAccepted,
//                     onChanged: (value) {
//                       setState(() {
//                         _termsAccepted = value!;
//                       });
//                     },
//                   ),
//                   const Expanded(
//                     child: Text(
//                       'I accept the terms and conditions',
//                       style: TextStyle(fontSize: 14.0),
//                     ),
//                   ),
//                 ],
//               ),
//               if (!_termsAccepted)
//                 const Text(
//                   'You must accept the terms and conditions',
//                   style: TextStyle(color: Colors.red, fontSize: 12.0),
//                 ),
//               const SizedBox(height: 16.0),

//               // Submit Button
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     if (_formKey.currentState!.validate() && _termsAccepted) {
//                       _submitApplication();
//                     } else if (!_termsAccepted) {
//                       _showToast('You must accept the terms and conditions');
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     padding: const EdgeInsets.symmetric(vertical: 14.0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: const Text(
//                     'Submit Application',
//                     style: TextStyle(fontSize: 16.0),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Helper method to build text fields
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     String? Function(String?)? validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//       ),
//       validator: validator,
//     );
//   }
// }
