import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'profile_screen.dart';
import 'data_cleanup_service.dart';
import 'package:url_launcher/url_launcher.dart';

final supabase = Supabase.instance.client;

class RequestRideScreen extends StatefulWidget {
  const RequestRideScreen({super.key});

  @override
  State<RequestRideScreen> createState() => _RequestRideScreenState();
}

class _RequestRideScreenState extends State<RequestRideScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const _RequestRideInput(),
    const _RequestRideInputForm(),
    const ProfileScreen(),
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
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Rides',
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
  List<Map<String, dynamic>> _offeredRides = [];

  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _cleanupExpiredData();
    _fetchOfferedRides();
    fetchRidesAndProfiles();
  }

  Future<void> _cleanupExpiredData() async {
    final cleanupService = DataCleanupService(supabase);
    await cleanupService.cleanupAllExpiredData();
  }

  Future<void> _fetchOfferedRides() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      try {
        final response = await supabase
            .from('rides')
            .select('*')
            .or('status.eq.pending,status.eq.accepted')
            //.eq('status', 'pending')
            //.neq('status', 'full')
            //.gt('seats_available', 2) // only rides with seats > 1
            .neq('user_id', userId)
            .order('created_at', ascending: false);

        if (mounted) {
          setState(() {
            _offeredRides = response;
            _filteredRides = response;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error fetching rides: $e')));
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _findRide(String query) {
    final search = query.toLowerCase();
    final minSeats = int.tryParse(_seatsController.text);

    setState(() {
      _filteredRides =
          _offeredRides.where((ride) {
            final dep = ride['departure'].toString().toLowerCase();
            final dest = ride['destination'].toString().toLowerCase();

            // Filter by place query (departure or destination)
            final matchesPlace = dep.contains(search) || dest.contains(search);

            // Filter by date if selected
            bool matchesDate = true;
            if (_selectedDate != null && ride['date'] != null) {
              final rideDate = DateTime.tryParse(ride['date']);
              if (rideDate == null) return false;
              matchesDate =
                  rideDate.year == _selectedDate!.year &&
                  rideDate.month == _selectedDate!.month &&
                  rideDate.day == _selectedDate!.day;
            }

            // Filter by minimum seats if provided
            bool matchesSeats = true;
            if (minSeats != null) {
              final seats =
                  int.tryParse(ride['seats_available'].toString()) ?? 0;
              matchesSeats = seats == minSeats;
            }

            return matchesPlace && matchesDate && matchesSeats;
          }).toList();
    });
  }

  void _launchWhatsApp(String phoneNumber, String message) async {
    final whatsappUrl = Uri.parse(
      'whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}',
    );
    final webUrl = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      print('Unable to launch WhatsApp');
    }
  }

  Future<void> _updateRideStatus(String rideId, String status) async {
    try {
      await supabase.from('rides').update({'status': status}).eq('id', rideId);
      if (mounted) {
        setState(() {
          _offeredRides.removeWhere((r) => r['id'] == rideId);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }

  Future<void> fetchRidesAndProfiles() async {
    try {
      final currentUserId = supabase.auth.currentUser!.id;

      // Fetch rides not offered by the logged-in user
      final rides = await supabase
          .from('rides')
          .select()
          .not('user_id', 'eq', currentUserId)
          .or(
            'status.eq.pending,status.eq.accepted',
          ) // Only rides with status pending or accepted
          .gt('seats_available', 0) // Only rides with available seats
          .order('created_at', ascending: false);

      // Extract unique user IDs from these rides
      final userIds =
          rides.map<String>((r) => r['user_id'].toString()).toSet().toList();

      // Fetch matching profiles
      final profiles = await supabase
          .from('profiles')
          .select('id, name')
          .filter('id', 'in', '(${userIds.join(',')})');

      // Map user_id -> name
      userProfiles = {for (var p in profiles) p['id'].toString(): p['name']};

      // Save rides to state
      setState(() {
        _filteredRides = List<Map<String, dynamic>>.from(rides);
      });
    } catch (error) {
      print('Error fetching rides or profiles: $error');
    }
  }

  void _showContactInfo(BuildContext context, Map<String, dynamic> profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder:
          (_) => DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 24,
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            'Contact Details',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        _infoTile(Icons.person, 'Name', profile['name']),
                        _infoTile(Icons.cake, 'Age', profile['age']),
                        _infoTile(
                          Icons.phone_android,
                          'Mobile',
                          profile['mobile'],
                        ),
                        _infoTile(
                          Icons.card_membership,
                          'License',
                          profile['license'],
                        ),
                        _infoTile(Icons.badge, 'Aadhaar', profile['aadhaar']),
                        _infoTile(Icons.email, 'Email', profile['email']),
                        _infoTile(Icons.wc, 'Gender', profile['gender']),
                        const SizedBox(height: 36),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () async {
                                  final mobile = profile['mobile'];
                                  final Uri url = Uri.parse('tel:$mobile');
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not launch dialer',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text(
                                  'Call',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.deepPurple,
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Close',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _infoTile(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 26, color: Colors.deepPurple.shade400),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value?.toString() ?? 'N/A',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.deepPurple.shade400,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  final TextEditingController _seatsController = TextEditingController();
  Map<String, dynamic> userProfiles = {}; // user_id -> profile map

  List<Map<String, dynamic>> _filteredRides = []; // Rides after filtering

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) => _findRide(value),
              decoration: InputDecoration(
                labelText: 'Search for a place',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _selectedDate != null
                            ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                            : 'Select Date',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _seatsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min Seats',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _findRide(_searchController.text),
                icon: const Icon(Icons.search),
                label: const Text('Find Ride'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Available Rides',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (_filteredRides.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text('No offered rides available.'),
              )
            else
              ListView.separated(
                itemCount: _filteredRides.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final ride = _filteredRides[index];
                  final offeredBy =
                      userProfiles[ride['user_id'].toString()] ?? 'Unknown';
                  final date =
                      ride['date'] != null
                          ? DateFormat(
                            'dd/MM/yyyy',
                          ).format(DateTime.parse(ride['date']))
                          : 'N/A';
                  final time = ride['time'] ?? 'N/A';

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${ride['departure']} → ${ride['destination']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Offered by: $offeredBy'),
                          Text('Date: $date • Time: $time'),
                          Text('Seats: ${ride['seats_available']}'),
                          Text('Price: ₹${ride['price']}'),
                          Text(
                            'Vehicle: ${ride['vehicle_make']} ${ride['vehicle_model']} (${ride['vehicle_color']})',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final profile =
                                        await supabase
                                            .from('profiles')
                                            .select('name, mobile')
                                            .eq('id', ride['user_id'])
                                            .single();

                                    final requesterPhone = profile['mobile'];
                                    final requesterName = profile['name'];

                                    final currentProfile =
                                        await supabase
                                            .from('profiles')
                                            .select()
                                            .eq(
                                              'id',
                                              supabase.auth.currentUser!.id,
                                            )
                                            .single();

                                    final message = '''
Hi $requesterName,

I’ve accepted your ride from *${ride['departure']}* to *${ride['destination']}* on *$date at $time*.

My details:
• Name: ${currentProfile['name']}
• Age: ${currentProfile['age']}
• Phone: ${currentProfile['mobile']}
• License: ${currentProfile['license']}
• Aadhaar: ${currentProfile['aadhaar'] ?? 'Not provided'}

Let’s coordinate further here.
Thanks!
''';

                                    final rideId = ride['id'];

                                    final currentRide =
                                        await supabase
                                            .from('rides')
                                            .select('seats_available')
                                            .eq('id', rideId)
                                            .single();

                                    final currentSeats =
                                        currentRide['seats_available'] ?? 0;
                                    final updatedSeats = currentSeats - 1;

                                    final updates = {
                                      'seats_available': updatedSeats,
                                      if (updatedSeats == 0) 'status': 'full',
                                    };

                                    await supabase
                                        .from('rides')
                                        .update(updates)
                                        .eq('id', rideId);

                                    await _fetchOfferedRides();

                                    _launchWhatsApp(requesterPhone, message);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('ACCEPT'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed:
                                      () => _updateRideStatus(
                                        ride['id'],
                                        'declined',
                                      ),
                                  child: const Text('DECLINE'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final profile =
                                    await supabase
                                        .from('profiles')
                                        .select(
                                          'name, age, mobile, license, aadhaar, email, gender',
                                        )
                                        .eq('id', ride['user_id'])
                                        .single();

                                if (profile != null) {
                                  _showContactInfo(context, profile);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  232,
                                  156,
                                  15,
                                ),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('CONTACT'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
// class _RequestRideInputForm extends StatelessWidget {
//   const _RequestRideInputForm();

//   @override
//   Widget build(BuildContext context) {
//     return const Center(child: Text('Input Form Here'));
//   }
// }

class _RequestRideInputForm extends StatefulWidget {
  const _RequestRideInputForm();

  @override
  State<_RequestRideInputForm> createState() => _RequestRideInputFormState();
}

class _RequestRideInputFormState extends State<_RequestRideInputForm> {
  final List<Map<String, dynamic>> _requestedRides = [];

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int? _selectedSeats;

  @override
  void initState() {
    super.initState();
    _loadRequestedRides();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
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
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _loadRequestedRides() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('ride_requests')
          .select()
          .eq('requester_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _requestedRides.clear();
        _requestedRides.addAll(List<Map<String, dynamic>>.from(data));
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load rides: $e')));
    }
  }

  Future<void> _deleteRequestedRide(String rideId) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    try {
      await supabase
          .from('ride_requests')
          .delete()
          .eq('id', rideId)
          .eq('requester_id', userId);

      setState(() {
        _requestedRides.removeWhere((ride) => ride['id'] == rideId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride request deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting ride: $e')));
    }
  }

  Future<void> _submitRideRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to submit a ride request')),
      );
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    final from = _fromController.text.trim();
    final to = _toController.text.trim();
    final price = _priceController.text.trim();
    final seats = _selectedSeats;

    final priceRange = '₹$price';

    try {
      final response =
          await Supabase.instance.client.from('ride_requests').insert({
            'requester_id': user.id,
            'from_location': from,
            'to_location': to,
            'price_range': priceRange,
            'status': 'pending',
            'no_of_seats': seats,
            'date': _selectedDate!.toIso8601String(),
            'time': _selectedTime!.format(context),
          }).select();

      if (response.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add ride request')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride request submitted successfully')),
        );

        _fromController.clear();
        _toController.clear();
        _priceController.clear();
        _selectedSeats = null;
        _selectedDate = null;
        _selectedTime = null;

        setState(() {});

        _loadRequestedRides();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting request: $e')));
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _fetchAcceptorProfileAndShowDialog(
    BuildContext context,
    Map<String, dynamic> rideRequest,
  ) async {
    try {
      final acceptorUserId = rideRequest['accepted_by_user_id'];
      if (acceptorUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user has accepted this ride yet')),
        );
        return;
      }

      // Fetch the acceptor's profile from the profiles table
      final profile =
          await supabase
              .from('profiles')
              .select('name, email, mobile, aadhaar, license, age, gender')
              .eq('id', acceptorUserId)
              .single();

      if (profile == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile not found')));
        return;
      }

      _showProfileDialog(context, profile);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching profile: $e')));
    }
  }

  void _showProfileDialog(BuildContext context, Map<String, dynamic> profile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          elevation: 20,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_pin_circle,
                          size: 48,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'User Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow(Icons.person, 'Name', profile['name']),
                        _buildInfoRow(Icons.email, 'Email', profile['email']),
                        _buildInfoRow(Icons.phone, 'Mobile', profile['mobile']),
                        _buildInfoRow(
                          Icons.credit_card,
                          'Aadhaar',
                          profile['aadhaar'],
                        ),
                        _buildInfoRow(
                          Icons.card_membership,
                          'License',
                          profile['license'],
                        ),
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Age',
                          profile['age']?.toString(),
                        ),
                        _buildInfoRow(Icons.wc, 'Gender', profile['gender']),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          label: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    final displayValue = (value == null || value.isEmpty) ? 'N/A' : value;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 26, color: Colors.deepPurple),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputSpacing = const SizedBox(height: 16);

    return Scaffold(
      appBar: AppBar(title: const Text('Request a Ride'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _fromController,
                    decoration: const InputDecoration(
                      labelText: 'From',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Please enter origin'
                                : null,
                  ),
                  inputSpacing,
                  TextFormField(
                    controller: _toController,
                    decoration: const InputDecoration(
                      labelText: 'To',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Please enter destination'
                                : null,
                  ),
                  inputSpacing,
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.calendar_today),
                          hintText:
                              _selectedDate == null
                                  ? 'Select date'
                                  : DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(_selectedDate!),
                        ),
                        validator:
                            (_) =>
                                _selectedDate == null
                                    ? 'Please select a date'
                                    : null,
                      ),
                    ),
                  ),
                  inputSpacing,
                  GestureDetector(
                    onTap: () => _selectTime(context),
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Time',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.access_time),
                          hintText:
                              _selectedTime == null
                                  ? 'Select time'
                                  : _selectedTime!.format(context),
                        ),
                        validator:
                            (_) =>
                                _selectedTime == null
                                    ? 'Please select a time'
                                    : null,
                      ),
                    ),
                  ),
                  inputSpacing,
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Seats',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.event_seat),
                    ),
                    value: _selectedSeats,
                    items:
                        [1, 2, 3, 4, 5]
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.toString()),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedSeats = val;
                      });
                    },
                    validator:
                        (val) => val == null ? 'Select number of seats' : null,
                  ),
                  inputSpacing,
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price per rider',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter price';
                      }
                      if (double.tryParse(value.trim()) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _submitRideRequest,
                      child: const Text(
                        'SUBMIT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              'Requested Rides',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 1.5),
            const SizedBox(height: 10),
            _requestedRides.isEmpty
                ? const Center(
                  child: Text(
                    'No requested rides yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
                : ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _requestedRides.length,
                  itemBuilder: (context, index) {
                    final ride = _requestedRides[index];
                    final formattedDate =
                        ride['date'] != null
                            ? DateFormat(
                              'dd/MM/yyyy',
                            ).format(DateTime.parse(ride['date']))
                            : 'N/A';

                    final status = (ride['status'] ?? 'unknown').toString();
                    final statusColor = _getStatusColor(status);

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        title: Text(
                          '${ride['from_location']} → ${ride['to_location']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date: $formattedDate  •  Time: ${ride['time'] ?? 'N/A'}',
                              ),
                              Text('Seats: ${ride['no_of_seats']}'),
                              Text('Price: ₹${ride['price_range']}'),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (status == 'accepted')
                                    TextButton.icon(
                                      onPressed: () {
                                        _fetchAcceptorProfileAndShowDialog(
                                          context,
                                          ride,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.visibility,
                                        size: 18,
                                      ),
                                      label: const Text('View'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.indigo,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        textStyle: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Delete request',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder:
                                  (_) => AlertDialog(
                                    title: const Text('Delete Request'),
                                    content: const Text(
                                      'Are you sure you want to delete this ride request?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deleteRequestedRide(ride['id']);
                                          Navigator.pop(context);
                                        },
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
