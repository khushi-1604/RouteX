import 'package:supabase_flutter/supabase_flutter.dart';

class DataCleanupService {
  final SupabaseClient supabase;

  DataCleanupService(this.supabase);

  Future<void> cleanupExpiredRides() async {
    try {
      final today = DateTime.now().toIso8601String();

      final expiredRides =
          await supabase.from('rides').select('id, date').lt('date', today)
              as List;

      for (var ride in expiredRides) {
        final rideId = ride['id'];
        await supabase.from('rides').delete().eq('id', rideId);
        print('Deleted expired ride $rideId');
      }
    } catch (e) {
      print('Error cleaning up expired rides: $e');
    }
  }

  Future<void> cleanupExpiredRequestRides() async {
    try {
      final today = DateTime.now().toIso8601String();

      final expiredRequests =
          await supabase
                  .from('ride_requests')
                  .select('id, date')
                  .lt('date', today)
              as List;

      for (var request in expiredRequests) {
        final requestId = request['id'];
        await supabase.from('ride_requests').delete().eq('id', requestId);
        print('Deleted expired request ride $requestId');
      }
    } catch (e) {
      print('Error cleaning up expired request rides: $e');
    }
  }

  Future<void> cleanupAllExpiredData() async {
    await cleanupExpiredRides();
    await cleanupExpiredRequestRides();
  }
}
