// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert'; // 导入 json 相关
import 'package:http/http.dart' as http; // 导入 http
import '../utils.dart';

class Event {
  final String title;

  Event(this.title);

  @override
  String toString() => title;
}

class TableEventsExample extends StatefulWidget {
  const TableEventsExample({super.key});

  @override
  _TableEventsExampleState createState() => _TableEventsExampleState();
}

class _TableEventsExampleState extends State<TableEventsExample> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> kEvents = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));

    // 获取特定月份的事件
    _fetchEvents(_focusedDay.year.toString(),
        _focusedDay.month.toString().padLeft(2, '0'));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  // 获取特定月份的事件
  Future<void> _fetchEvents(String year, String month) async {
    final response = await http
        .get(Uri.parse('http://localhost:6201/monthItems/$year-$month'));

    if (response.statusCode == 200) {
      // 解析返回的 JSON 数据，使用 UTF-8 解码
      Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));

      // 清空现有事件
      kEvents.clear();

      for (var eventData in data['data']) {
        DateTime date = DateTime.parse(eventData['date']);
        List<Event> events =
            (eventData['tasks'] as List).map((task) => Event(task)).toList();

        // 将事件存储到 kEvents 中
        kEvents[date] = events;

        // 这里打印出每天的任务数量和任务
        print(
            'Date: ${eventData['date']}, Task Count: ${eventData['task_count']}, Tasks: $events');
      }

      setState(() {
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });
    } else {
      // 如果接口请求失败，使用模拟数据
      _loadMockData();
    }
  }

  void _loadMockData() {
    // 如果 API 请求失败，用模拟数据
    kEvents = {
      DateTime(2024, 8, 1): [],
      DateTime(2024, 8, 2): [],
      DateTime(2024, 8, 3): [],
      DateTime(2024, 8, 4): [],
      DateTime(2024, 8, 5): [],
      DateTime(2024, 8, 6): [],
      DateTime(2024, 8, 7): [],
      DateTime(2024, 8, 8): [],
      DateTime(2024, 8, 9): [],
      DateTime(2024, 8, 10): [],
      DateTime(2024, 8, 11): [],
      DateTime(2024, 8, 12): [],
      DateTime(2024, 8, 13): [],
      DateTime(2024, 8, 14): [
        Event("在2024年8月14日 08:00:00时与金主爸爸讨论人生"),
        Event("我借给西西8块钱")
      ],
      DateTime(2024, 8, 15): [],
      DateTime(2024, 8, 16): [],
      DateTime(2024, 8, 17): [Event("2024年8月17日上午8点有个会，主要关于采购价格策略")],
      DateTime(2024, 8, 18): [],
      DateTime(2024, 8, 19): [],
      DateTime(2024, 8, 20): [],
      DateTime(2024, 8, 21): [],
      DateTime(2024, 8, 22): [],
      DateTime(2024, 8, 23): [Event("2024-08-23 10:00:00和团队讨论发展策略的会议")],
      DateTime(2024, 8, 24): [],
      DateTime(2024, 8, 25): [],
      DateTime(2024, 8, 26): [],
      DateTime(2024, 8, 27): [],
      DateTime(2024, 8, 28): [],
      DateTime(2024, 8, 29): [],
      DateTime(2024, 8, 30): [Event("2024年8月30日，我要去买旅行装备")],
      DateTime(2024, 8, 31): [],
    };

    _selectedEvents.value = _getEventsForDay(_selectedDay!);
  }

  List<Event> _getEventsForDay(DateTime day) {
    return kEvents[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('TableCalendar - Events'),
      // ),
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2034, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _selectedEvents.value = _getEventsForDay(selectedDay);
            },
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              // 显示事件数量
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        title: Text('${value[index]}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
// class TableEventsExample extends StatefulWidget {
//   const TableEventsExample({super.key});

//   @override
//   _TableEventsExampleState createState() => _TableEventsExampleState();
// }

// class _TableEventsExampleState extends State<TableEventsExample> {
//   late final ValueNotifier<List<Event>> _selectedEvents;
//   final CalendarFormat _calendarFormat = CalendarFormat.month;
//   RangeSelectionMode _rangeSelectionMode = RangeSelectionMode
//       .toggledOff; // Can be toggled on/off by longpressing a date
//   DateTime _focusedDay = DateTime.now();
//   DateTime? _selectedDay;
//   DateTime? _rangeStart;
//   DateTime? _rangeEnd;

//   @override
//   void initState() {
//     super.initState();

//     _selectedDay = _focusedDay;
//     _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
//   }

//   @override
//   void dispose() {
//     _selectedEvents.dispose();
//     super.dispose();
//   }

//   List<Event> _getEventsForDay(DateTime day) {
//     // Implementation example
//     return kEvents[day] ?? [];
//   }

//   List<Event> _getEventsForRange(DateTime start, DateTime end) {
//     // Implementation example
//     final days = daysInRange(start, end);

//     return [
//       for (final d in days) ..._getEventsForDay(d),
//     ];
//   }

//   void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
//     if (!isSameDay(_selectedDay, selectedDay)) {
//       setState(() {
//         _selectedDay = selectedDay;
//         _focusedDay = focusedDay;
//         _rangeStart = null; // Important to clean those
//         _rangeEnd = null;
//         _rangeSelectionMode = RangeSelectionMode.toggledOff;
//       });

//       _selectedEvents.value = _getEventsForDay(selectedDay);
//     }
//   }

//   void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
//     setState(() {
//       _selectedDay = null;
//       _focusedDay = focusedDay;
//       _rangeStart = start;
//       _rangeEnd = end;
//       _rangeSelectionMode = RangeSelectionMode.toggledOn;
//     });

//     // `start` or `end` could be null
//     if (start != null && end != null) {
//       _selectedEvents.value = _getEventsForRange(start, end);
//     } else if (start != null) {
//       _selectedEvents.value = _getEventsForDay(start);
//     } else if (end != null) {
//       _selectedEvents.value = _getEventsForDay(end);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // appBar: AppBar(
//       //   title: Text('TableCalendar - Events'),
//       // ),
//       body: Column(
//         children: [
//           TableCalendar<Event>(
//             firstDay: kFirstDay,
//             lastDay: kLastDay,
//             focusedDay: _focusedDay,
//             selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//             rangeStartDay: _rangeStart,
//             rangeEndDay: _rangeEnd,
//             calendarFormat: _calendarFormat,
//             rangeSelectionMode: _rangeSelectionMode,
//             eventLoader: _getEventsForDay,
//             startingDayOfWeek: StartingDayOfWeek.monday,
//             calendarStyle: const CalendarStyle(
//               // Use `CalendarStyle` to customize the UI
//               outsideDaysVisible: false,
//             ),
//             onDaySelected: _onDaySelected,
//             onRangeSelected: _onRangeSelected,
//             onFormatChanged: (format) {
//               if (_calendarFormat != format) {
//                 setState(() {
//                   _calendarFormat = format;
//                 });
//               }
//             },
//             onPageChanged: (focusedDay) {
//               _focusedDay = focusedDay;
//             },
//           ),
//           const SizedBox(height: 8.0),
//           Expanded(
//             child: ValueListenableBuilder<List<Event>>(
//               valueListenable: _selectedEvents,
//               builder: (context, value, _) {
//                 return ListView.builder(
//                   itemCount: value.length,
//                   itemBuilder: (context, index) {
//                     return Container(
//                       margin: const EdgeInsets.symmetric(
//                         horizontal: 12.0,
//                         vertical: 4.0,
//                       ),
//                       decoration: BoxDecoration(
//                         border: Border.all(),
//                         borderRadius: BorderRadius.circular(12.0),
//                       ),
//                       child: ListTile(
//                         onTap: () => print('${value[index]}'),
//                         title: Text('${value[index]}'),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
