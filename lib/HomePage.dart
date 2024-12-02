import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  late Box<Map> _eventsBox;
  Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _eventsBox = Hive.box<Map>('events'); // Initialize Hive box
    _loadEvents(); // Load existing events
  }

  // Check for second Saturdays
  bool _isSecondSaturday(DateTime day) {
    if (day.weekday == DateTime.saturday) {
      int dayOfMonth = day.day;
      return dayOfMonth > 7 && dayOfMonth <= 14;
    }
    return false;
  }

  // Load events from Hive
  void _loadEvents() {
    setState(() {
      _events = _eventsBox.toMap().map((key, value) => MapEntry(
            DateTime.parse(key),
            List<String>.from(value['events'] ?? []),
          ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[400],
        title: const Text(
          'Calendar',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            color: Colors.white,
            onPressed: () => _showAllEventsDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar widget
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _showAddEventDialog(context, selectedDay);
            },
            eventLoader: (day) {
              return _events[day] ?? [];
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue[200],
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.deepPurple[400],
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                if (day.weekday == DateTime.sunday || _isSecondSaturday(day)) {
                  return Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          // Events list
         Expanded(
  child: _selectedDay != null && _events[_selectedDay] != null
      ? ListView.builder(
          reverse: true,
          itemCount: _events[_selectedDay]!.length,
          itemBuilder: (context, index) {
            final event = _events[_selectedDay]![index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Dismissible(
                key: Key(event),  // Unique key for each event
                direction: DismissDirection.endToStart, // Allow swipe from right to left
                onDismissed: (direction) {
                  // Remove event on dismiss
                  setState(() {
                    _events[_selectedDay]!.removeAt(index);
                    if (_events[_selectedDay]!.isEmpty) {
                      _events.remove(_selectedDay);
                    }
                    // Update the Hive box to persist changes
                    _eventsBox.put(
                      _selectedDay!.toIso8601String(),
                      {'events': _events[_selectedDay]},
                    );
                  });

                  // Show a snackbar when the event is dismissed
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Event dismissed'),
                    duration: const Duration(seconds: 2),
                  ));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(
                      event,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        )
      : const Center(
          child: Text(
            'No events for the selected day.',
            style: TextStyle(fontSize: 16.0, fontStyle: FontStyle.italic),
          ),
        ),
),

        ],
      ),
    );
  }

  // Add event dialog
  void _showAddEventDialog(BuildContext context, DateTime selectedDay) {
    TextEditingController _eventController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Event'),
          content: TextField(
            controller: _eventController,
            decoration: InputDecoration(
              hintText: 'Enter event details',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_eventController.text.isNotEmpty) {
                  setState(() {
                    if (_events[selectedDay] != null) {
                      _events[selectedDay]!.add(_eventController.text);
                    } else {
                      _events[selectedDay] = [_eventController.text];
                    }
                    _eventsBox.put(
                      selectedDay.toIso8601String(),
                      {'events': _events[selectedDay]},
                    );
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Show all events
  void _showAllEventsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('All Events'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              children: _events.entries.map((entry) {
                DateTime day = entry.key;
                List<String> events = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${day.day}-${day.month}-${day.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...events.asMap().entries.map((event) {
                      int index = event.key;
                      String eventName = event.value;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple[200],
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(
                            eventName,
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _events[day]!.removeAt(index);
                                if (_events[day]!.isEmpty) {
                                  _events.remove(day);
                                  _eventsBox.delete(day.toIso8601String());
                                } else {
                                  _eventsBox.put(
                                    day.toIso8601String(),
                                    {'events': _events[day]},
                                  );
                                }
                              });
                              Navigator.pop(context);
                              _showAllEventsDialog(context);
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
