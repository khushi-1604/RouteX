import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyOfferedRidesScreen extends StatefulWidget {
  const MyOfferedRidesScreen({Key? key}) : super(key: key);

  @override
  _MyOfferedRidesScreenState createState() => _MyOfferedRidesScreenState();
}

class _MyOfferedRidesScreenState extends State<MyOfferedRidesScreen> {
  List<Map<String, dynamic>> _offeredRides = [];

  @override
  void initState() {
    super.initState();
    _fetchOfferedRides();
  }

  Future<void> _fetchOfferedRides() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId != null) {
      try {
        final data = await supabase
            .from('rides')
            .select()
            .eq('user_id', userId)
            .order('date', ascending: true)
            .limit(100);

        setState(() {
          _offeredRides = List<Map<String, dynamic>>.from(data);
        });
      } catch (e) {
        print('Error fetching rides: $e');
      }
    } else {
      print('User not logged in');
    }
  }

  Future<void> _deleteRide(String rideId) async {
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
          .from('rides')
          .delete()
          .eq('id', rideId)
          .eq('user_id', userId);

      setState(() {
        _offeredRides.removeWhere((ride) => ride['id'] == rideId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride deleted successfully')),
      );
    } catch (e) {
      print('Error deleting ride: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting ride: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Offered Rides'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _offeredRides.isEmpty
                ? const Center(
                  child: Text(
                    'No offered rides yet.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _fetchOfferedRides,
                  child: ListView.builder(
                    itemCount: _offeredRides.length,
                    itemBuilder: (context, index) {
                      final ride = _offeredRides[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                        elevation: 3,
                        shadowColor: Colors.blueAccent.withOpacity(0.3),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          title: LayoutBuilder(
                            builder: (context, constraints) {
                              return SizedBox(
                                width: constraints.maxWidth,
                                child: Text(
                                  '${ride['departure']} → ${ride['destination']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.blueAccent.shade700,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    ride['date'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blueAccent.shade700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.blueAccent.shade700,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    ride['time'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blueAccent.shade700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Seats: ${ride['seats_available']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueAccent.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Delete Ride'),
                                    content: const Text(
                                      'Are you sure you want to delete this ride?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deleteRide(ride['id']);
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
                      );
                    },
                  ),
                ),
      ),
      backgroundColor: Colors.white,
    );
  }
}
