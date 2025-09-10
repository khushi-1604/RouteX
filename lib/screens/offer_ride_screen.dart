import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offer_ride_form_screen.dart';
import 'my_offered_rides_screen.dart';
import 'profile_screen.dart';
import 'package:intl/intl.dart';
import 'data_cleanup_service.dart';
import 'package:url_launcher/url_launcher.dart';

class OfferRideMainScreen extends StatefulWidget {
  const OfferRideMainScreen({super.key});

  @override
  State<OfferRideMainScreen> createState() => _OfferRideMainScreenState();
}

class _OfferRideMainScreenState extends State<OfferRideMainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    OfferRideContent(),
    MyOfferedRidesScreen(),
    ProfileScreen(),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Find Ride'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Rides'),
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

class OfferRideContent extends StatefulWidget {
  const OfferRideContent({super.key});

  @override
  State<OfferRideContent> createState() => _OfferRideContentState();
}

class _OfferRideContentState extends State<OfferRideContent> {
  final supabase = Supabase.instance.client;
  List<dynamic> _rideRequests = [];

  @override
  void initState() {
    super.initState();
    _cleanupExpiredData();
    _fetchRideRequests();
    fetchRidesAndProfiles();
  }

  Future<void> _cleanupExpiredData() async {
    final cleanupService = DataCleanupService(supabase);
    await cleanupService.cleanupAllExpiredData();
  }

  Future<void> _fetchRideRequests() async {
    final user = supabase.auth.currentUser?.id;
    if (user != null) {
      try {
        final response = await supabase
            .from('ride_requests')
            .select(
              '*, profiles(name,mobile,age, license, aadhaar, email, gender), date, time',
            )
            .eq('status', 'pending')
            .neq('requester_id', user);

        if (mounted) {
          setState(() {
            _rideRequests = response;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching requests: $e')),
          );
        }
      }
    }
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
      print('WhatsApp not installed and web URL cannot be launched');
    }
  }

  Future<void> _updateRequestStatus(
    String requestId,
    String status,
    String? acceptedByUserId,
  ) async {
    try {
      final updateData = {'status': status};
      if (acceptedByUserId != null) {
        updateData['accepted_by_user_id'] = acceptedByUserId; // 👈 add this
      }
      await supabase
          .from('ride_requests')
          .update(updateData)
          //.update({'status': status})
          .eq('id', requestId);

      if (mounted) {
        setState(() {
          _rideRequests.removeWhere((r) => r['id'] == requestId);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating request: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OfferRideFormScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Post a Ride'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          const Text(
            'Ride Requests',
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10.0),
          Expanded(
            child:
                _rideRequests.isEmpty
                    ? const Center(child: Text('No ride requests yet.'))
                    : ListView.builder(
                      //itemCount: _filteredRides.length,
                      itemCount: _rideRequests.length,
                      itemBuilder: (context, index) {
                        //final ride = _filteredRides[index];
                        final currentUserId = supabase.auth.currentUser!.id;
                        final request = _rideRequests[index];
                        final requesterName =
                            request['profiles']?['name'] ?? 'Unknown';
                        final from = request['from_location'] ?? 'N/A';
                        final to = request['to_location'] ?? 'N/A';
                        final seats =
                            request['no_of_seats']?.toString() ?? 'N/A';
                        final rawDate = request['date'];
                        final rawTime = request['time'];
                        String formattedDateTime = 'N/A';

                        final dateTimeString = '$rawDate $rawTime';
                        final dateTime = DateTime.parse(dateTimeString);
                        formattedDateTime = DateFormat(
                          'dd MMM yyyy, hh:mm a',
                        ).format(dateTime);

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Requested by: $requesterName',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 20),
                                    const SizedBox(width: 8),
                                    Text('From: $from → To: $to'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Departure: $formattedDateTime'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.event_seat, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Seats Required: $seats'),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          final userId =
                                              supabase.auth.currentUser!.id;
                                          final currentUserProfile =
                                              await supabase
                                                  .from('profiles')
                                                  .select()
                                                  .eq('id', userId)
                                                  .single();

                                          final requesterPhone =
                                              request['profiles']['mobile'];
                                          final requesterName =
                                              request['profiles']['name'];

                                          if (requesterPhone == null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Requester phone number is missing',
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          final message =
                                              'Hi $requesterName,\n\n'
                                              'I have accepted your ride request for the journey from *$from* to *$to* on *$formattedDateTime*, requiring *$seats* seat(s).\n\n'
                                              'Here are my details:\n'
                                              '• Name: ${currentUserProfile['name']}\n'
                                              '• Age: ${currentUserProfile['age']}\n'
                                              '• Phone: ${currentUserProfile['mobile']}\n'
                                              '• License No.: ${currentUserProfile['license']}\n'
                                              '• Aadhaar No.: ${currentUserProfile['aadhaar'] ?? 'Not provided'}\n\n'
                                              "Let's coordinate further on this chat.\n"
                                              'Thank you!';

                                          await _updateRequestStatus(
                                            request['id'],
                                            'accepted',
                                            currentUserId,
                                          );
                                          _launchWhatsApp(
                                            requesterPhone,
                                            message,
                                          );
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
                                            () => _updateRequestStatus(
                                              request['id'],
                                              'declined',
                                              currentUserId,
                                            ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(
                                            color: Colors.redAccent,
                                          ),
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
                                    onPressed: () {
                                      final profile = request['profiles'];
                                      if (profile != null) {
                                        _showContactInfo(context, profile);
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'No contact info available',
                                            ),
                                          ),
                                        );
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
          ),
        ],
      ),
    );
  }

  // Add this helper method in your widget class:
  Map<String, dynamic> userProfiles = {}; // user_id -> profile map

  List<Map<String, dynamic>> _filteredRides = []; // Rides after filtering
  Future<void> fetchRidesAndProfiles() async {
    try {
      final currentUserId = supabase.auth.currentUser!.id;

      // Fetch rides not offered by the logged-in user
      final rides = await supabase
          .from('rides')
          .select()
          .not('user_id', 'eq', currentUserId)
          .or('status.eq.pending,status.eq.accepted')
          .gt('seats_available', 0)
          .order('created_at', ascending: false);

      // Extract unique user IDs
      final userIds =
          rides.map<String>((r) => r['user_id'].toString()).toSet().toList();

      // Fetch profiles with full info
      final profiles = await supabase
          .from('profiles')
          .select('id, name, age, mobile, license, aadhaar, email, gender')
          .filter('id', 'in', '(${userIds.join(',')})');

      // Map user_id -> full profile
      userProfiles = {for (var p in profiles) p['id'].toString(): p};

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
}
