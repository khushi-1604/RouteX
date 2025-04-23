// offer_ride_form_screen.dart
import 'package:flutter/material.dart';

class OfferRideFormScreen extends StatefulWidget {
  const OfferRideFormScreen({super.key});

  @override
  State<OfferRideFormScreen> createState() => _OfferRideFormScreenState();
}

class _OfferRideFormScreenState extends State<OfferRideFormScreen> {
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _availableSeats = 1;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _vehicleMakeController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehicleColorController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026), // Adjust as needed
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _offerRide() {
    // TODO: Implement logic to save the offered ride details to Supabase
    print('Offering ride with:');
    print('Departure: ${_departureController.text}');
    print('Destination: ${_destinationController.text}');
    print('Date: $_selectedDate');
    print('Time: $_selectedTime');
    print('Seats: $_availableSeats');
    print('Price: ${_priceController.text}');
    print(
      'Vehicle: ${_vehicleMakeController.text} ${_vehicleModelController.text} (${_vehicleColorController.text})',
    );
    // After saving, you would typically navigate to a confirmation screen or back to the offer ride main screen.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Ride')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFormField(
              controller: _departureController,
              decoration: const InputDecoration(
                labelText: 'From',
                hintText: 'Enter departure location',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              // TODO: Implement auto-suggestions
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'To',
                hintText: 'Enter destination',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              // TODO: Implement auto-suggestions
            ),
            const SizedBox(height: 16.0),
            Row(
              children: <Widget>[
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        hintText: 'Select date',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        _selectedDate == null
                            ? 'Select date'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        hintText: 'Select time',
                        prefixIcon: Icon(Icons.access_time_outlined),
                      ),
                      child: Text(
                        _selectedTime == null
                            ? 'Select time'
                            : '${_selectedTime!.format(context)}',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              children: <Widget>[
                const Text(
                  'Available Seats:',
                  style: TextStyle(fontSize: 16.0),
                ),
                const SizedBox(width: 16.0),
                DropdownButton<int>(
                  value: _availableSeats,
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _availableSeats = newValue;
                      });
                    }
                  },
                  items:
                      <int>[1, 2, 3, 4, 5].map<DropdownMenuItem<int>>((
                        int value,
                      ) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value'),
                        );
                      }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price per Rider (₹)',
                hintText: 'Enter price',
                prefixIcon: Icon(Icons.currency_rupee_outlined),
              ),
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _vehicleMakeController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Make (Optional)',
                hintText: 'Enter vehicle make',
                //prefixIcon: Icon(Icons.car_outlined),
              ),
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _vehicleModelController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Model (Optional)',
                hintText: 'Enter vehicle model',
                prefixIcon: Icon(Icons.model_training_outlined),
              ),
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _vehicleColorController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Color (Optional)',
                hintText: 'Enter vehicle color',
                prefixIcon: Icon(Icons.color_lens_outlined),
              ),
            ),
            const SizedBox(height: 32.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _offerRide,
                child: const Text('Offer Ride'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
