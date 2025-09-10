import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final SupabaseClient supabase;
  late final String userId;

  @override
  void initState() {
    super.initState();
    supabase = Supabase.instance.client;
    userId = supabase.auth.currentUser?.id ?? '';
  }

  // Function to fetch profile as a stream
  Stream<Map<String, dynamic>> _fetchUserProfileStream() {
    return supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) => rows.isNotEmpty ? rows.first : {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        // Use StreamBuilder to listen to profile data in real-time
        stream: _fetchUserProfileStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No profile data found'));
          }

          final profile = snapshot.data!;
          final String avatarUrl =
              'https://sxixpxndhbprzuiusure.supabase.co/storage/v1/object/public/profile-images/khushi.jpg'; // Your avatar URL field from the DB

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile image
                  ClipOval(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Maybe open a bigger profile picture viewer
                        },
                        child: CircleAvatar(
                          radius: 75,
                          backgroundImage:
                              avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : const AssetImage(
                                        'assets/default_avatar.png',
                                      )
                                      as ImageProvider,
                          child:
                              avatarUrl.isEmpty
                                  ? const Icon(
                                    Icons.account_circle,
                                    size: 75,
                                    color: Colors.grey,
                                  )
                                  : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Profile details in a Card for better organization
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          Text(
                            profile['name'] ?? 'No Name',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Gender
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Gender: ${profile['gender'] ?? 'Not specified'}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Age
                          Row(
                            children: [
                              const Icon(
                                Icons.cake,
                                size: 20,
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 10),
                              Text('Age: ${profile['age'] ?? 'Not specified'}'),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Phone number
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 20,
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Phone: ${profile['mobile'] ?? 'Not specified'}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Aadhaar
                          Row(
                            children: [
                              const Icon(
                                Icons.credit_card,
                                size: 20,
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Aadhaar: ${profile['aadhaar'] ?? 'Not specified'}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // License number
                          Row(
                            children: [
                              const Icon(Icons.directions_car, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'License: ${profile['license'] ?? 'Not specified'}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Email
                          Row(
                            children: [
                              const Icon(
                                Icons.email,
                                size: 20,
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Email: ${profile['email'] ?? 'Not specified'}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Edit Profile button (you can navigate to the edit screen)
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to the edit profile screen
                      Navigator.pushNamed(context, '/home');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 40,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Back', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
