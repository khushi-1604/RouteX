import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      lastDate: DateTime(2026),
    );
    if (picked != null) {
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
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _offerRide() async {
    final supabase = Supabase.instance.client;

    if (_departureController.text.isEmpty ||
        _destinationController.text.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null ||
        _priceController.text.isEmpty ||
        _vehicleMakeController.text.isEmpty ||
        _vehicleModelController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not logged in')));
        return;
      }

      await supabase.from('rides').insert({
        'departure': _departureController.text.trim(),
        'destination': _destinationController.text.trim(),
        'date': _selectedDate!.toIso8601String().split('T')[0],
        'time':
            '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        'seats_available': _availableSeats,
        'price': double.parse(_priceController.text),
        'vehicle_make': _vehicleMakeController.text.trim(),
        'vehicle_model': _vehicleModelController.text.trim(),
        'vehicle_color':
            _vehicleColorController.text.trim().isNotEmpty
                ? _vehicleColorController.text.trim()
                : null,
        'user_id': userId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride offered successfully!')),
      );

      _departureController.clear();
      _destinationController.clear();
      _priceController.clear();
      _vehicleMakeController.clear();
      _vehicleModelController.clear();
      _vehicleColorController.clear();
      setState(() {
        _selectedDate = null;
        _selectedTime = null;
        _availableSeats = 1;
      });
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${error.toString()}')));
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType inputType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(16.0), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Post a Ride',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade400,
        elevation: 2,
      ),
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            _buildCard(
              Column(
                children: [
                  _buildTextField(
                    controller: _departureController,
                    label: 'From',
                    hint: 'Enter departure location',
                    icon: Icons.location_on_outlined,
                  ),
                  _buildTextField(
                    controller: _destinationController,
                    label: 'To',
                    hint: 'Enter destination',
                    icon: Icons.flag_outlined,
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Date',
                              prefixIcon: const Icon(
                                Icons.calendar_today_outlined,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            child: Text(
                              _selectedDate == null
                                  ? 'Select date'
                                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Time',
                              prefixIcon: const Icon(
                                Icons.access_time_outlined,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            child: Text(
                              _selectedTime == null
                                  ? 'Select time'
                                  : _selectedTime!.format(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      const Text(
                        'Available Seats:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 20),
                      DropdownButton<int>(
                        value: _availableSeats,
                        onChanged: (value) {
                          setState(() {
                            _availableSeats = value!;
                          });
                        },
                        items:
                            [1, 2, 3, 4, 5].map((value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value'),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildCard(
              Column(
                children: [
                  _buildTextField(
                    controller: _priceController,
                    label: 'Price per Rider (₹)',
                    hint: 'Enter price',
                    icon: Icons.currency_rupee_outlined,
                    inputType: TextInputType.number,
                  ),
                  _buildTextField(
                    controller: _vehicleMakeController,
                    label: 'Vehicle Name',
                    hint: 'Enter vehicle name',
                  ),
                  _buildTextField(
                    controller: _vehicleModelController,
                    label: 'Vehicle Number',
                    hint: 'Enter vehicle number',
                    icon: Icons.directions_car_outlined,
                  ),
                  _buildTextField(
                    controller: _vehicleColorController,
                    label: 'Vehicle Color (Optional)',
                    hint: 'Enter vehicle color',
                    icon: Icons.color_lens_outlined,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _offerRide,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Offer Ride', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
