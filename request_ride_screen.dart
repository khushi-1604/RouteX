import 'package:flutter/material.dart';
//import 'profile_screen.dart'; // Import the profile screen

class RequestRideScreen extends StatefulWidget {
  const RequestRideScreen({super.key});

  @override
  State<RequestRideScreen> createState() => _RequestRideScreenState();
}

class _RequestRideScreenState extends State<RequestRideScreen> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    const _RequestRideInput(), // Contains the "Search for a place..." UI
    const _RequestRideInputForm(), // The new UI for the "Rides" tab (was history)
    //const ProfileScreen(), // Profile screen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request a Ride')),
      body: Center(child: _widgetOptions[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Home', // Shows the search/input UI
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer), // Changed icon to reflect input
            label: 'Rides', // Now shows the input form
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _RequestRideInput extends StatefulWidget {
  const _RequestRideInput();

  @override
  State<_RequestRideInput> createState() => _RequestRideInputState();
}

class _RequestRideInputState extends State<_RequestRideInput> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

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

  void _findRide() {
    // TODO: Implement logic to search for rides
    print('Searching for a ride with:');
    print('Location: ${_searchController.text}');
    print('Date: $_selectedDate');
    print('Time: $_selectedTime');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search for a place...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
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
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _selectedDate == null
                          ? 'Date'
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
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _selectedTime == null
                          ? 'Time'
                          : '${_selectedTime!.format(context)}',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _findRide,
              child: const Text('FIND RIDE'),
            ),
          ),
          const SizedBox(height: 20.0),
          const Text(
            'Available rides',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10.0),
          // TODO: Implement UI to display available rides
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Driver Name   ₹ 150'),
                Text('Today • 9:00 AM   2 seats left'),
                Divider(),
                // Add more available ride items here
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestRideInputForm extends StatefulWidget {
  const _RequestRideInputForm();

  @override
  State<_RequestRideInputForm> createState() => _RequestRideInputFormState();
}

class _RequestRideInputFormState extends State<_RequestRideInputForm> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int? _selectedSeats;
  final TextEditingController _priceController = TextEditingController();

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

  void _submitRideRequest() {
    // TODO: Implement logic to handle the submitted ride request
    print('Requesting ride with:');
    print('From: ${_fromController.text}');
    print('To: ${_toController.text}');
    print('Date: $_selectedDate');
    print('Time: $_selectedTime');
    print('Seats: $_selectedSeats');
    print('Price: ${_priceController.text}');
    // After submitting, you might want to navigate to a confirmation or loading screen.
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            controller: _fromController,
            decoration: const InputDecoration(labelText: 'From'),
          ),
          TextFormField(
            controller: _toController,
            decoration: const InputDecoration(labelText: 'To'),
          ),
          InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Date'),
              child: Text(
                _selectedDate == null
                    ? 'Select Date'
                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              ),
            ),
          ),
          InkWell(
            onTap: () => _selectTime(context),
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Time'),
              child: Text(
                _selectedTime == null
                    ? 'Select Time'
                    : '${_selectedTime!.format(context)}',
              ),
            ),
          ),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Seats'),
            value: _selectedSeats,
            items:
                <int>[1, 2, 3, 4, 5].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value'),
                  );
                }).toList(),
            onChanged: (int? newValue) {
              setState(() {
                _selectedSeats = newValue;
              });
            },
          ),
          TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Price per rider'),
          ),
          const SizedBox(height: 24.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitRideRequest,
              child: const Text('SUBMIT'),
            ),
          ),
        ],
      ),
    );
  }
}
