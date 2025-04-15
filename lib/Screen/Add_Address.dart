import 'package:flutter/material.dart';
import '../Model/MosqueModel.dart';

class AddAddress extends StatefulWidget {
  final MosqueModel mosque;

  const AddAddress({super.key, required this.mosque});

  @override
  _AddAddressState createState() => _AddAddressState();
}

class _AddAddressState extends State<AddAddress> {
  late TextEditingController addressC, latitudeC, longitudeC;

  @override
  void initState() {
    super.initState();
    addressC = TextEditingController(
      text: widget.mosque.address ?? "Address not available",
    );
    latitudeC = TextEditingController(
      text: widget.mosque.latitude.toString(),
    );
    longitudeC = TextEditingController(
      text: widget.mosque.longitude.toString(),
    );
  }

  @override
  void dispose() {
    addressC.dispose();
    latitudeC.dispose();
    longitudeC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Delivery Location")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Delivery Address",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: addressC,
              decoration: const InputDecoration(
                labelText: "Mosque Address",
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: latitudeC,
              decoration: const InputDecoration(
                labelText: "Latitude",
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: longitudeC,
              decoration: const InputDecoration(
                labelText: "Longitude",
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _saveDeliveryLocation(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Center(
                child: Text(
                  "Confirm & Use This Location",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveDeliveryLocation(BuildContext context) {
    // Use a SnackBar, or remove if not needed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Delivery location saved successfully!")),
    );

    // Return the data to the calling screen
    Navigator.pop(context, {
      'address': addressC.text,
      'latitude': latitudeC.text,
      'longitude': longitudeC.text,
    });
  }
}
