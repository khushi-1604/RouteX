import 'package:flutter/material.dart';
import 'request_ride_screen.dart';
import 'offer_ride_form_screen.dart';

class OfferRideMainScreen extends StatefulWidget {
  const OfferRideMainScreen({super.key});

  @override
  State<OfferRideMainScreen> createState() => _OfferRideMainScreenState();
}

class _OfferRideMainScreenState extends State<OfferRideMainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    _OfferRideContent(), // Contains "Post a Ride" and "Ride Requests"
    // Placeholder for a list of offered rides
    Center(child: Text('Your Offered Rides', style: TextStyle(fontSize: 20))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offer a Ride')),
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Find Ride', // Navigates to RequestRideScreen for now
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Rides', // Will show list of offered rides
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

class _OfferRideContent extends StatelessWidget {
  const _OfferRideContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OfferRideFormScreen(),
                  ),
                );
              },
              child: const Text('Post a Ride'),
            ),
          ),
          const SizedBox(height: 20.0),
          const Text(
            'Ride Requests',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10.0),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('From Location'),
                const Text('To Location'),
                const Text('Today • 9:00 AM'),
                const SizedBox(height: 10.0),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement logic for "Start Ride"
                      print('Start Ride tapped');
                    },
                    child: const Text('START RIDE'),
                  ),
                ),
              ],
            ),
          ),
          // TODO: Add a ListView here to show multiple ride requests
        ],
      ),
    );
  }
}
