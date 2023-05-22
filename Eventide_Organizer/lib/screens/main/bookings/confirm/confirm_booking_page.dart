import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventide_organizer_app/components/custom_text_poppins.dart';
import 'package:eventide_organizer_app/controllers/booking_controller.dart';
import 'package:eventide_organizer_app/models/booking_model.dart';
import 'package:eventide_organizer_app/providers/auth/user_provider.dart';
import 'package:eventide_organizer_app/screens/main/bookings/confirm/booking_item.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class ConfirmedBookingPage extends StatefulWidget {
  const ConfirmedBookingPage({super.key});

  @override
  State<ConfirmedBookingPage> createState() => _ConfirmedBookingPageState();
}

class _ConfirmedBookingPageState extends State<ConfirmedBookingPage> {
  final List<BookingModel> _bookings = [];

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Consumer<UserProvider>(
      builder: (context, value, child) {
        return StreamBuilder<QuerySnapshot>(
            stream: BookingController().getBookings(value.organizerModel!.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: CustomText("No Bookings yet"),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              Logger().i(snapshot.data!.docs.length);
              _bookings.clear();

              for (var e in snapshot.data!.docs) {
                Map<String, dynamic> data = e.data() as Map<String, dynamic>;
                var model = BookingModel.fromJason(data);

                _bookings.add(model);
              }
              return ListView.separated(
                  itemBuilder: (context, index) => ConfirmedBookingItem(
                        bookingModel: _bookings
                            .where((e) => e.status == 'confirmed')
                            .elementAt(index),
                        index: index,
                      ),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 40),
                  itemCount:
                      _bookings.where((e) => e.status == 'confirmed').length);
            });
      },
    ));
  }
}
