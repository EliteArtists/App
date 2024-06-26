import 'dart:convert';

import 'package:app_user/app/backend/parse/events_creation_parse.dart';
import 'package:app_user/app/controller/events_creation_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:app_user/app/backend/models/event_contract_model.dart';
import 'package:app_user/app/controller/booking_controller.dart';
import 'package:app_user/app/util/toast.dart';
import 'package:app_user/app/view/home.dart';
import 'package:app_user/app/view/notification_screen/widgets/notification_list_widget.dart';
import 'package:app_user/app/util/theme.dart';
import './nego_dialog.dart';

class NewEventRequestDialogPending extends StatelessWidget {
  final EventContractModel eventContractData;

  // Update the constructor to make 'eventContractData' optional with a default value of null
  const NewEventRequestDialogPending({
    Key? key,
    required this.eventContractData,
  }) : super(key: key);

  // @override
  // void initState() {
  //   super.initState();

  //   _selectedDay = _focusedDay;
  //   final kEventSource = {
  //     for (final item in controller.savedEventContractsList)
  //       item.date!: [
  //         "Data Selection (${DateFormat.yMMMMEEEEd().format(item.date!)}, ${item.time})"
  //       ]
  //   };
  //   // if (controller.selectedDay != null) {
  //   //   kEventSource.addAll({
  //   //     controller.selectedDay!: [
  //   //       "Data Selection (${DateFormat.yMMMMEEEEd().format(controller.selectedDay!)} ${controller.selectedTime})"
  //   //     ],
  //   //   });
  //   // }

  //   eventsList = LinkedHashMap<DateTime, List<String>>(
  //     equals: isSameDay,
  //     hashCode: getHashCode,
  //   )..addAll(kEventSource);

  //   _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  // }
  void _selectDate(
    BuildContext context,
    BookingController controller,
  ) async {

    // Show loading popup to block the UI and indicate that the request is being processed.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog.fullscreen(
          backgroundColor: const Color.fromARGB(255, 0, 0, 0), // Bac
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
            ],
          ),
        );
      },
    );

    // Fetch the events for the musician/DJ.
    Response response;
    final EventsCreationParser parser = Get.find();
    response = await parser.getSavedEventContracts({
      'individual_id': eventContractData.individualId ?? 0,
      'salon_id': eventContractData.salonId ?? 0,
    });
    Map<DateTime, DateTime> savedEventContractsDates = {};
    if (response.statusCode == 200) {
      Map<String, dynamic> myMap = Map<String, dynamic>.from(response.body);
      List<EventContractModel> savedEventContractsList = myMap['data']
          .map<EventContractModel>((item) => EventContractModel.fromJson(item))
          .toList();
      // Extract date-time of the events.
      for(final event in savedEventContractsList) {
        if(event.status == 'Declined' || event.status == 'Deleted') { continue; }
        if(event.date == null) { continue; }
        DateTime startTime = toTimeSlot(event.date!);
        savedEventContractsDates[startTime] = getEndTimeSlot(startTime, event.time);
      }
    }

    // Fetch unavailable dates for this musician.
    Response unavailableDatesResponse = await parser.getUnavailableDatesById({
      'individual_id': eventContractData.individualId ?? 0,
      'salon_id': eventContractData.salonId ?? 0,
    });
    List<DateTime> unavailableDatesList = [];
    if (unavailableDatesResponse.statusCode == 200) {
      Map<String, dynamic> myMap = Map<String, dynamic>.from(unavailableDatesResponse.body);
        unavailableDatesList = (myMap['data'] as List<dynamic>)
            .map<DateTime>((item) => DateTime.parse(item.toString()))
            .toSet().toList();
    }

    // Pop loading dialog.
    Navigator.of(context).pop();

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: eventContractData.date ?? DateTime.now(),
      //firstDate: DateTime(2023),
      firstDate: DateTime.now(),  // So that
      lastDate: DateTime(2027),
      selectableDayPredicate: (day) {
        DateTime initial = eventContractData.date ?? DateTime.now();
        // If date is not in unavailable list it is selectable.
        return !unavailableDatesList.contains(day);
      },
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        initialEntryMode: TimePickerEntryMode.inputOnly,
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        // Combine the date and time to create a DateTime object
        DateTime updatedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        int slotMinutes = getSlotMinutes(eventContractData.time);

        DateTime updatedSlotDateTime = toTimeSlot(updatedDateTime);

        bool isUpdatedTimeSlotValid = true;
        // Before 11AM is not allowed.
        if(updatedSlotDateTime.hour < 11) {
          isUpdatedTimeSlotValid = false;
        }
        // Check if musician is available for the slot.
        else {
          savedEventContractsDates.forEach((key, value) {
            DateTime newStart = key.subtract(Duration(minutes: slotMinutes));
            debugPrint("$updatedSlotDateTime newStart: $newStart value: $value");
            if(updatedSlotDateTime.compareTo(newStart) > 0 && updatedSlotDateTime.compareTo(value) < 0) {
              isUpdatedTimeSlotValid = false;
              return;
            }
          });
        }

        debugPrint("savedEventContractsDates: $savedEventContractsDates");

        if(!isUpdatedTimeSlotValid) {
          // Get events on this particular day.
          Map<DateTime, DateTime> eventsOnDay = {};
          savedEventContractsDates.forEach((key, value) {
            if(DateTime(updatedSlotDateTime.year, updatedSlotDateTime.month, updatedSlotDateTime.day).compareTo(
              DateTime(key.year, key.month, key.day)) == 0) {
              eventsOnDay[key] = value;
            }
          });

          // Sort events slots by time.
          var sortedEventsOnDay = Map.fromEntries(eventsOnDay.entries.toList()..sort((e1, e2) => e1.key.compareTo(e2.key)));
          List<DateTime> slots = [];
          sortedEventsOnDay.forEach((key, value) {
            slots.add(key);
            slots.add(value);
          });

          Map<DateTime, DateTime> availableSlots = {};
          for(int i = 0; i < slots.length; i += 2) {
            // First slot.
            if(i == 0) {
              DateTime firstSlotTime = DateTime(updatedDateTime.year, updatedDateTime.month, updatedDateTime.day, 11);
              int diffMinutes = slots[i].difference(firstSlotTime).inMinutes;
              if(diffMinutes >= slotMinutes) {
                DateTime endTime = slots[i].subtract(Duration(minutes: slotMinutes));
                if(endTime.compareTo(firstSlotTime) < 0) {
                  availableSlots[firstSlotTime] = endTime;
                }
              }
            }
            // Intermediate slots.
            else {
              int diffMinutes = slots[i].difference(slots[i - 1]).inMinutes;
              if(diffMinutes >= slotMinutes) {
                availableSlots[slots[i - 1]] = slots[i].subtract(Duration(minutes: slotMinutes));
              }
            }
            // Last slot.
            if(i == slots.length - 2) {
              DateTime lastSlotTime = DateTime.utc(updatedDateTime.year, updatedDateTime.month, updatedDateTime.day, 23, 45);
              int diffMinutes = lastSlotTime.difference(slots[i + 1]).inMinutes;
              if(diffMinutes >= slotMinutes - 15) {
                //DateTime startTime = slots[i + 1].add(const Duration(minutes: 15));
                DateTime startTime = slots[i + 1];
                availableSlots[startTime] = lastSlotTime.subtract(Duration(minutes: slotMinutes - 15));
              }
            }
          }

          // Builds slots string.
          String slotsStr = "";
          availableSlots.forEach((key, value) {
            slotsStr += "\n${DateFormat('hh:mm a').format(key)} - ${DateFormat('hh:mm a').format(value)}";
          });

          debugPrint("availableSlots: $availableSlots");

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Unavailable", style: TextStyle(color: Colors.redAccent)),
                content: Text(
                      "The performer is not available on ${DateFormat('EEEE, d MMMM yyyy').format(updatedSlotDateTime)} at ${DateFormat('h:mm a').format(updatedSlotDateTime)} slot."
                      "\n\nFor same day, choose a time between: $slotsStr"
                    ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
          return;
        }

        debugPrint("updatedSlotDateTime: $updatedSlotDateTime");

        // FIXME: This is to prevent below code from running for development. Once development is done, remove this.
        // return;

        // Call the update method to send the updated date and time to the backend
        bool updateSuccess = await controller.updateEventContractDate(
          updatedSlotDateTime,
          eventContractData,
        );

        debugPrint('Update success: $updateSuccess');

        if (updateSuccess) {
          // Send notification upon successful update
          controller.sendNotificationOnUpdate(
            eventContractData,
            updatedSlotDateTime,
          );
          // Show success Snackbar
          successToast('Event updated successfully');
        } else {
          // Show error Snackbar
          showToast('Failed to update event');
        }
      }
    }
  }

  DateTime toTimeSlot(DateTime dateTime) {
    int minutes = (dateTime.minute / 15).floor() * 15;
    return DateTime.utc(dateTime.year, dateTime.month, dateTime.day, dateTime.hour, minutes, 0);
  }

  DateTime getEndTimeSlot(DateTime startTime, String? time) {
    if(time == null) { return startTime; }
    int minutes = getSlotMinutes(time);
    DateTime endTime = startTime.add(Duration(minutes: minutes));
    return toTimeSlot(endTime);
  }

  int getSlotMinutes(String? time) {
    if(time == null) { return 0; }
    Map<String, int> slotMinutes = {"2 x 45-minute sets": 120, "2 x 1-hour sets": 130, "3 x 45-minute sets": 180, "4 x 45-minute sets": 240};
    return slotMinutes[time]!;
  }

  void _showConfirmationDialog(BuildContext context,
      BookingController controller, EventContractModel notificationData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Withdraw Offer"),
          content: Text(
              "Are you sure you want to withdraw the offer? This action is permanent."),
          actions: [
            TextButton(
              onPressed: () {
                controller.updateEventContractStatus(
                    eventContractData, 'Deleted');
                controller.onCancelSubmit(eventContractData);
                Navigator.of(context).pop();
                //  Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(builder: (context) => HomeScreen()),
                // );
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                // Perform the action when 'No' is clicked
                Navigator.of(context).pop();
                // Add your logic here for 'No'
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  void _showWithdrawDialog(BuildContext context, BookingController controller,
      EventContractModel notificationData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Extend Deadline"),
          content: Text("Do you want to extend the deadline for the artist ?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Remove this line
                _showExtendDialog(context, controller, notificationData);
                // Add your logic here for 'Yes'
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showConfirmationDialog(context, controller, notificationData);
                // Add your logic here for 'No'
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  void _showExtendDialog(BuildContext context, BookingController controller,
      EventContractModel notificationData) {
    DateTime selectedDate = DateTime.now(); // Initial date value

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Extend Deadline"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Select the new date"),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  // Show date picker
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101), // Adjust the end date as needed
                  );

                  // Update selectedDate if a date is picked
                  if (pickedDate != null && pickedDate != selectedDate) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
                child: Text('Pick Date'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                String formattedDate =
                    DateFormat('MM/dd/yyyy').format(selectedDate);
                print('Selected Date: $formattedDate');

                // Call onWithdrawalSubmit from the passed controller instance
                controller.onWithdrawalSubmit(eventContractData, formattedDate);
                controller.updateEventContractDate(
                    selectedDate, eventContractData);
                Navigator.of(context).pop();
              },
              child: Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BookingController>(
      builder: (controller) {
        String timeoneString = eventContractData!.date != null
            ? DateFormat('HH:mm').format(eventContractData!.date!)
            : '';

        double timeone = timeoneString.isNotEmpty
            ? double.parse(timeoneString.split(':')[0]) +
                double.parse(timeoneString.split(':')[1]) / 60
            : 0.0;

// Ensure the resulting time doesn't go below 0:00
// Ensure the resulting time doesn't go below 0:00
        timeone = timeone - 1.00 < 0.0 ? 0.0 : timeone - 1.00;

// Convert the result back to HH:mm format using only floating-point division
        String resultTime =
            '${(timeone.floor()).toString().padLeft(2, '0')}:${((timeone % 1) * 60).toInt().toString().padLeft(2, '0')}';

// Add 19 minutes to the resultTime

        return Dialog.fullscreen(
          backgroundColor: const Color.fromARGB(255, 0, 0, 0), // Bac
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width *
                  .85, // Adjust the width as needed
              padding: EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the popup
                        },
                      ),
                    ],
                  ),

                  Text(
                    "Contract", // Title at the center
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                        color: Colors.red),
                  ),
                  SizedBox(height: 20),
                  // Row(
                  //   children: [
                  //     Flexible(
                  //       child: Container(
                  //         padding:
                  //             EdgeInsets.all(8), // Adjust padding as needed
                  //         decoration: BoxDecoration(
                  //           color:
                  //               Colors.grey[800], // Dark gray background color
                  //           borderRadius: BorderRadius.circular(
                  //               10), // Adjust the radius as needed
                  //         ),
                  //         child: Text(
                  //           "Soulaunge is happy to announce your contract creation, in this section you can see the information about your new booking.",
                  //           style: TextStyle(
                  //             color: const Color.fromARGB(255, 255, 255, 255),
                  //             fontSize: 16, // Adjust the font size as needed
                  //             decoration: TextDecoration.none,
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //     // Add other widgets if needed
                  //   ],
                  // ),

                  SizedBox(height: 20),
                  // 2.0 Venue Name
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Icon(
                              //   Icons.supervised_user_circle,
                              //   color: Colors.white,
                              //   size: 16, // White icon
                              // ),
                              SizedBox(width: 10),
                              Text(
                                "Venue", // Add your bigger title here
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      20, // Adjust the font size as needed
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 10),
                          Text(
                            eventContractData.venueName.toString(),
                            style: TextStyle(
                              color: ThemeProvider.appColor,
                              fontFamily: 'bold',
                              fontSize: 14,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      // Other widgets...
                    ],
                  ),
                  SizedBox(height: 20),
                  // 1.0 Venue Contact
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Icon(
                              //   Icons.contact_page,
                              //   color: Colors.white,
                              //   size: 16, // White icon
                              // ),
                              SizedBox(width: 10),
                              Text(
                                "Venue Contact", // Add your bigger title here
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      20, // Adjust the font size as needed
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 10),
                          Text(
                            eventContractData!.mobile.toString(),
                            style: TextStyle(
                              color: ThemeProvider.appColor,
                              fontFamily: 'bold',
                              fontSize: 14,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      // Other widgets...
                    ],
                  ),

                  SizedBox(height: 20),
                  // 1.0 Venue Contact
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Icon(
                              //   Icons.edit_road_sharp,
                              //   color: Colors.white,
                              //   size: 16, // White icon
                              // ),
                              SizedBox(width: 10),
                              Text(
                                "Venue Address", // Add your bigger title here
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      20, // Adjust the font size as needed
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              eventContractData!.venueAddress.toString(),
                              style: TextStyle(
                                color: ThemeProvider.appColor,
                                fontFamily: 'bold',
                                fontSize: 14,
                                decoration: TextDecoration.none,
                              ),
                              textAlign:
                                  TextAlign.right, // Align text to the right
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 10),
                      // Other widgets...
                    ],
                  ),

                  SizedBox(height: 20),
                  // 2.1 Date and Time
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Icon(
                              //   Icons.calendar_today,
                              //   color: Colors.white,
                              //   size: 16, // White icon
                              // ),
                              SizedBox(width: 10),
                              Text(
                                "Performance Date", // Add your bigger title here
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      20, // Adjust the font size as needed
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 10),
                          Text(
                            eventContractData!.date != null
                                ? DateFormat('MMMM d, y')
                                    .format(eventContractData!.date!)
                                : '',
                            style: TextStyle(
                              color: ThemeProvider.appColor,
                              fontFamily: 'bold',
                              fontSize: 14,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      // Other widgets...
                    ],
                  ),

                  SizedBox(height: 20),
                  // 1.0 Musician Name
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Icon(
                              //   Icons.contact_page,
                              //   color: Colors.white,
                              //   size: 16, // White icon
                              // ),
                              SizedBox(width: 10),
                              Text(
                                "Musician", // Add your bigger title here
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      20, // Adjust the font size as needed
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 10),
                          Text(
                            eventContractData!.musician.toString(),
                            style: TextStyle(
                              color: ThemeProvider.appColor,
                              fontFamily: 'bold',
                              fontSize: 14,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      // Other widgets...
                    ],
                  ),

                  SizedBox(height: 20),
                  // 2.2 Minutes
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              // Icon(
                              //   Icons.timer,
                              //   color: Colors.white,
                              //   size: 16,
                              // ),
                              SizedBox(width: 10),
                              Text(
                                "Set Time(s)",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 10),
                          Text(
                            "${timeoneString}  /",
                            style: const TextStyle(
                              color: ThemeProvider.appColor,
                              fontFamily: 'bold',
                              fontSize: 14,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          Text(
                            eventContractData!.time.toString(),
                            style: const TextStyle(
                              color: ThemeProvider.appColor,
                              fontFamily: 'bold',
                              fontSize: 14,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      // Other widgets...
                    ],
                  ),

                  SizedBox(height: 20),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              // Icon(
                              //   Icons.volume_up,
                              //   color: Colors.white,
                              //   size: 16, // White icon
                              // ),
                              SizedBox(width: 10),
                              Text(
                                "Sound Check", // Add your bigger title here
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      20, // Adjust the font size as needed
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 10),
                          Text(
                            resultTime,
                            style: TextStyle(
                              color: ThemeProvider.appColor,
                              fontFamily: 'bold',
                              fontSize: 14,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      // Other widgets...
                    ],
                  ),
                  SizedBox(height: 20),
                  // 2.4 Fees
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Icon(
                              //   Icons.attach_money,
                              //   color: Colors.white,
                              //   size: 16, // White icon
                              // ),
                              SizedBox(width: 10),
                              Text(
                                "Price", // Add your bigger title here
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      20, // Adjust the font size as needed
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 10),
                          Text(
                            '£ ${eventContractData.fee.toString()}',
                            style: TextStyle(
                              color: ThemeProvider.appColor,
                              fontFamily: 'bold',
                              fontSize: 14,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10), // Adjust the height as needed
                      // Other widgets...
                    ],
                  ),

                  SizedBox(height: 20),

                  // 2.5 Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(), // Divider on top
                      Row(
                        children: [
                          // Icon(
                          //   Icons.description,
                          //   color: Colors.white,
                          //   size: 16, // White icon
                          // ),
                          SizedBox(width: 10),
                          Text(
                            "Notes", // Add your bigger title here
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20, // Adjust the font size as needed
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10), // Adjust the height as needed

                      Row(
                        children: [
                          SizedBox(width: 10),
                          Text(
                            "Info: ".tr,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          SizedBox(
                            width:
                                MediaQuery.of(context).size.width * .85 - 100,
                            child: Text(
                              eventContractData!.extraField.toString(),
                              style: TextStyle(
                                color: ThemeProvider.appColor,
                                fontFamily: 'bold',
                                fontSize: 14,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10), // Adjust the height as needed
                      Divider(), // Divider on bottom
                    ],
                  ),

                  SizedBox(height: 10),
                  // 2.6 Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Icon(
                          //   Icons.policy,
                          //   color: Colors.white,
                          //   size: 16, // White icon
                          // ),
                          SizedBox(width: 10),
                          Text(
                            "Status", // Add your bigger title here
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20, // Adjust the font size as needed
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10), // Adjust the height as needed

                      Row(
                        children: [
                          SizedBox(width: 10),
                          Text(
                            "Status: ".tr,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          Text(
                            eventContractData!.status.toString(),
                            style: TextStyle(
                              color: ThemeProvider.appColor,
                              fontFamily: 'bold',
                              fontSize: 14,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      Divider(),
                    ],
                  ),

                  SizedBox(height: 40),
                  const Row(
                    children: [
                      // Icon(
                      //   Icons.history,
                      //   color: Colors.white,
                      //   size: 16, // White icon
                      // ),
                      SizedBox(width: 10),
                      Text(
                        "HISTORY", // Add your bigger title here
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20, // Adjust the font size as needed
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10),
                  // Inside your Column, after the Status section
                  SizedBox(height: 20),

                  // Add here
                  SizedBox(
                    height: 200,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.start,
                        spacing: 25.0,
                        runSpacing: 50.0,
                        children:
                            eventContractData.bodys!.split("/n").map((body) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Container(
                              //   width: 20,
                              //   height: 20,
                              //   decoration: BoxDecoration(
                              //     shape: BoxShape.circle,
                              //     color: Colors.white,
                              //   ),
                              // ),
                              SizedBox(width: 50),
                              Container(
                                constraints: BoxConstraints(
                                    maxWidth:
                                        200), // Adjust the maxWidth as needed
                                child: Text(
                                  body.trim(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      // Icon(
                      //   Icons.manage_accounts,
                      //   color: Colors.white,
                      //   size: 16, // White icon
                      // ),
                      SizedBox(width: 10),
                      Text(
                        "Manage", // Add your bigger title here
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20, // Adjust the font size as needed
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 8,
                        top: 10), // Adjust margins as needed
                    height: 2, // Adjust the height of the line
                    color: Colors.white, // Color of the line
                  ),
                  Visibility(
                    visible: eventContractData.status != 'Deleted',
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                                right: 8, top: 0), // Adjust margins as needed
                            child: ElevatedButton(
                              onPressed: () {
                                _showWithdrawDialog(
                                    context, controller, eventContractData);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors
                                    .red, // Set the background color to red
                                foregroundColor:
                                    Colors.white, // Set the text color to white
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      20.0), // Adjust the radius as needed
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Withdraw',
                                  style: TextStyle(
                                      fontSize: 10,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                                right: 8, top: 0), // Adjust margins as needed
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                controller.onChat(eventContractData);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors
                                    .white, // Set the background color to white
                                foregroundColor:
                                    Colors.black, // Set the text color to black
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      20.0), // Adjust the radius as needed
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Message',
                                  style: TextStyle(
                                      fontSize: 10.0,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                                right: 0, top: 0), // Adjust margins as needed
                            child: ElevatedButton(
                              onPressed: () {
                                _selectDate(context, controller);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors
                                    .white, // Set the background color to white
                                foregroundColor:
                                    Colors.black, // Set the text color to black
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      20.0), // Adjust the radius as needed
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Change Date',
                                  style: TextStyle(
                                      fontSize: 10.0,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 15),
                  Visibility(
                    visible: eventContractData.status != 'Deleted' &&
                        eventContractData.suggester ==
                            'owner', // Show the row if status is not 'Deleted'
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Icon(
                            //   Icons.toll_outlined,
                            //   color: Colors.white,
                            //   size: 16, // White icon
                            // ),
                            SizedBox(width: 10),
                            Text(
                              "ACTIONS", // Add your bigger title here
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20, // Adjust the font size as needed
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          margin: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 8,
                              top: 10), // Adjust margins as needed
                          height: 2, // Adjust the height of the line
                          color: Colors.white, // Color of the line
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Visibility(
                              visible: eventContractData.status == 'pending',
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();

                                  controller.updateEventContractStatus(
                                      eventContractData, 'Accepted');

                                  controller.onAcceptSubmit(eventContractData);
                                  controller.onChat(eventContractData);
                                },
                                child: Text("Accept",
                                    style: const TextStyle(
                                        color: Colors.orangeAccent,
                                        fontSize: 14)),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: eventContractData.status != 'Deleted' &&
                                  (eventContractData.status == 'pending' ||
                                      eventContractData.status != 'Accepted'),
                              child: ElevatedButton(
                                onPressed: () {
                                  Get.dialog(NegoDialog(
                                      eventContractData: eventContractData));
                                },
                                child: Text("Negotiate",
                                    style: const TextStyle(
                                        color: Colors.orangeAccent,
                                        fontSize: 14)),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: eventContractData.status == 'pending',
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  controller.updateEventContractStatus(
                                      eventContractData, 'Declined');
                                  controller.onDeclineSubmit(eventContractData);
                                  controller.onChat(eventContractData);
                                },
                                child: Text("Decline",
                                    style: const TextStyle(
                                        color: Colors.orangeAccent,
                                        fontSize: 14)),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void setState(Null Function() param0) {}
}
