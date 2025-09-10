import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/offer_ride_screen.dart';
import 'screens/CompleteProfileScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:
        'https://sxixpxndhbprzuiusure.supabase.co', // Replace with your Supabase URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN4aXhweG5kaGJwcnp1aXVzdXJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUyNDcwODIsImV4cCI6MjA2MDgyMzA4Mn0.1JVuD6FpC_b1c2IU9goJ_HjkzEN2QGqhXWS10cfhthk', // Replace with your Supabase Anon Key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RouteX',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: AuthScreen(), // Set AuthScreen as the initial screen
      routes: {
        '/home': (context) => const HomeScreen(), // Define your home route
        '/complete-profile': (context) => CompleteProfileScreen(),
        '/offer_ride_screen': (context) => OfferRideMainScreen(),
        '/login-screen': (context) => AuthScreen(),
      },
    );
  }
}
