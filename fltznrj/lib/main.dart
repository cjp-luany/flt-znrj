import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math';
import 'dart:ui';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart' as flutter_sound;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:time_planner/time_planner.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as path;
import 'pages/events_example.dart';

import 'package:flutter_z_location/flutter_z_location.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ChatController()),
        ChangeNotifierProvider(create: (context) => DrawerControllerClass()),
      ],
      child: MaterialApp(
        title: '日记助手',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Roboto',
          tabBarTheme: const TabBarTheme(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black,
            indicator: BoxDecoration(
              color: Colors.blue,
            ),
          ),
        ),
        home: const MyHomePage(),
        // scrollBehavior: MyCustomScrollBehavior(),
      ),
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

// * 以下是聊天控制器
class ChatController extends ChangeNotifier {
  List<Message> messages = [];

  void addMessage(String text, bool isUser) {
    messages.add(Message(isUser: isUser, text: text));
    if (isUser) {
      // 简单的AI助手回应
      Future.delayed(const Duration(seconds: 1), () {
        // messages.add(Message(isUser: false, text: '这是AI助手的回应'));
        notifyListeners();
      });
    }
    notifyListeners();
  }
}

// * 抽屉控制器
class DrawerControllerClass extends ChangeNotifier {
  bool isExpanded = false;

  void toggleDrawer() {
    isExpanded = !isExpanded;
    notifyListeners();
  }
}

// 主页面
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final drawerController = Provider.of<DrawerControllerClass>(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () => drawerController.toggleDrawer(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: drawerController.isExpanded ? 150 : 60,
                    color: Colors.white.withOpacity(0.8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                        if (drawerController.isExpanded)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const PlanningPage()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF007AFF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text('规划'),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const NotePage()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF007AFF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text('记事'),
                              ),
                            ],
                          )
                      ],
                    ),
                  ),
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      '日记助手',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: ChatContainer(),
                  ),
                ),
                const InputArea(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 聊天界面
class ChatContainer extends StatelessWidget {
  const ChatContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Provider.of<ChatController>(context);
    return ListView.builder(
      itemCount: chatController.messages.length,
      itemBuilder: (context, index) {
        final message = chatController.messages[index];
        return Align(
          alignment:
              message.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 250),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            margin: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: message.isUser
                  ? const Color(0xFF007AFF)
                  : const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }
}

// 消息类
class Message {
  final bool isUser;
  final String text;

  Message({required this.isUser, required this.text});
}

// 输入区域
class InputArea extends StatefulWidget {
  const InputArea({super.key});

  @override
  _InputAreaState createState() => _InputAreaState();
}

// 录音功能
class _InputAreaState extends State<InputArea> {
  final TextEditingController _controller = TextEditingController();
  late flutter_sound.FlutterSoundRecorder _recorder;
  late flutter_sound.FlutterSoundPlayer _player;

  bool _isRecording = false;
  bool _isPlaying = false;
  String _recordedFilePath = '';
  String _responseMessage = '';
  String _responseMessage2 = '';
  late Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _recorder = flutter_sound.FlutterSoundRecorder();
    _player = flutter_sound.FlutterSoundPlayer();
    _checkPermissions();
    _initialize();

    // 启动定时器
    // _startTimer();
  }

  Timer? _timer;

  void _startTimer() {
    // 每隔 3 分钟（180 秒）打印一次
    _timer = Timer.periodic(const Duration(minutes: 5), (Timer timer) async {
      // print('定时打印：${DateTime.now()}');

      final coordinate = await FlutterZLocation.getCoordinate();

      try {
        final Map<String, dynamic> jsonMap = {
          "latitude": coordinate.latitude,
          "longitude": coordinate.longitude
        };
        final String jsonString = jsonEncode(jsonMap);

        final response =
            await http.post(Uri.parse('http://47.115.151.97:6202/location/'),
                headers: {
                  'Content-Type': 'application/json; charset=utf-8',
                },
                body: jsonString);
      } catch (e) {
        print('位置获取失败: $e');
        // 提示用户位置获取失败
      }
    });
  }

  Future<void> _checkPermissions() async {
    // 检查并请求麦克风权限
    var microphoneStatus = await Permission.microphone.status;
    if (!microphoneStatus.isGranted) {
      await Permission.microphone.request();
    }

    // 检查并请求文件管理权限
    var storageStatus = await Permission.storage.status;
    if (!storageStatus.isGranted) {
      await Permission.storage.request();
    }

    // 检查并请求定位权限
    var locationStatus = await Permission.locationWhenInUse.status;
    if (!locationStatus.isGranted) {
      await Permission.locationWhenInUse.request();
    }
  }

  Future<void> _initialize() async {
    await _recorder.openAudioSession();
    await _player.openAudioSession();
  }

  Future<void> _startRecording() async {
    final dir = await path.getDownloadsDirectory();
    _recordedFilePath = '${dir?.path}/audio_example.wav';
    await _recorder.startRecorder(
      codec: flutter_sound.Codec.pcm16WAV,
      toFile: _recordedFilePath,
    );
    setState(() {
      _isRecording = true;
      _responseMessage = '';
      _responseMessage2 = '';
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });

    // 获取地理坐标
    await _getLocationAndUploadRecording(true, '');
  }

  Future<void> _getLocationAndUploadRecording(bool isWav, String text) async {
    // 获取当前位置

    double lat = 0.0;
    double lon = 0.0;

    try {
      // print("start location");
      // await _getCurrentLocation();

      // 获取GPS定位经纬度
      final coordinate = await FlutterZLocation.getCoordinate();
      // Provider.of<ChatController>(context, listen: false).addMessage(
      //     'Latitude: ${coordinate.latitude}, Longitude: ${coordinate.longitude}',
      //     false);

      lat = coordinate.latitude;
      lon = coordinate.longitude;

      // 使用位置数据
    } catch (e) {
      print('位置获取失败: $e');
      // 提示用户位置获取失败
    }

    if (isWav) {
      await _uploadRecording(lat, lon);
    } else {
      final Map<String, dynamic> jsonMap2 = {
        "query": text,
        "latitude": lat.toString(),
        "longitude": lon.toString()
      };
      final String jsonString2 = jsonEncode(jsonMap2);

      final response2 = await http.post(
        Uri.parse('http://47.115.151.97:6202/query/'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonString2,
      );

      if (response2.statusCode == 200) {
        String body2 = utf8.decode(response2.bodyBytes);
        var jsonData2 = jsonDecode(body2);

        setState(() {
          _responseMessage2 = jsonData2['Response'] ?? '没有返回结果';
        });

        Provider.of<ChatController>(context, listen: false)
            .addMessage(_responseMessage2, false);
      }
    }
    // 上传录音并传递位置
  }

  Future<void> _getCurrentLocation() async {
    Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            forceAndroidLocationManager: true)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
      });
    }).catchError((e) {
      print(e);
    });
  }

  Future<void> _uploadRecording(double latitude, double longitude) async {
    final File audioFile = File(_recordedFilePath);
    final List<int> fileBytes = await audioFile.readAsBytes();
    final String base64String = base64Encode(fileBytes);

    final Map<String, dynamic> jsonMap = {
      'audio': base64String,
      "audio_format": "wav",
      "sample_rate": 16000,
      "lang": "zh_cn",
      "punc": 1
    };

    final String jsonString = jsonEncode(jsonMap);

    final response = await http.post(
      Uri.parse('http://47.115.151.97:8090/paddlespeech/asr'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonString,
    );

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      var jsonData = jsonDecode(body);

      setState(() {
        _responseMessage = jsonData['result']['transcription'] ?? '没有返回结果';
      });

      Provider.of<ChatController>(context, listen: false)
          .addMessage(_responseMessage, true);

      final Map<String, dynamic> jsonMap2 = {
        "query": _responseMessage,
        "latitude": latitude.toString(),
        "longitude": longitude.toString()
      };
      final String jsonString2 = jsonEncode(jsonMap2);

      final response2 = await http.post(
        Uri.parse('http://47.115.151.97:6202/query/'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonString2,
      );

      if (response2.statusCode == 200) {
        String body2 = utf8.decode(response2.bodyBytes);
        var jsonData2 = jsonDecode(body2);

        setState(() {
          _responseMessage2 = jsonData2['Response'] ?? '没有返回结果';
        });

        Provider.of<ChatController>(context, listen: false)
            .addMessage(_responseMessage2, false);

        final Map<String, dynamic> jsonMap3 = {
          "text": _responseMessage2,
          "spk_id": 0,
          "speed": 1.0,
          "volume": 1.0,
          "sample_rate": 0,
          "save_path": "./tts.wav"
        };

        final String jsonString3 = jsonEncode(jsonMap3);

        final response3 = await http.post(
          Uri.parse('http://47.115.151.97:8090/paddlespeech/tts'),
          headers: {'Content-Type': 'application/json'},
          body: jsonString3,
        );

        if (response3.statusCode == 200) {
          String body3 = utf8.decode(response3.bodyBytes);
          var jsonData3 = jsonDecode(body3);
          var byteAudio = jsonData3['result']['audio'];

          final bytes = base64Decode(byteAudio);
          final dir = await path.getDownloadsDirectory();
          String wavFilePath = '${dir?.path}/output.wav';
          File wavFile = File(wavFilePath);
          await wavFile.writeAsBytes(bytes);

          bool exists = await wavFile.exists();
          if (exists) {
            print('WAV 文件已成功保存：$wavFilePath');

            await _player.startPlayer(fromURI: wavFilePath);
          } else {
            print('WAV 文件保存失败');
          }
        }
      }
    } else {
      print('上传失败: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> _startPlaying() async {
    await _player.startPlayer(
      fromURI: _recordedFilePath,
      whenFinished: () {
        setState(() {});
      },
    );
    setState(() {
      _isPlaying = true;
    });
  }

  Future<void> _stopPlaying() async {
    await _player.stopPlayer();
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  void dispose() {
    _recorder.closeAudioSession();
    _player.closeAudioSession();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.isNotEmpty) {
      Provider.of<ChatController>(context, listen: false)
          .addMessage(text, true);
      _controller.clear();

      _getLocationAndUploadRecording(false, text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: _handleSubmitted,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                filled: true,
                fillColor: const Color(0xFFF2F2F7),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(_isRecording ? Icons.stop : Icons.mic,
                color: const Color(0xFF007AFF)),
            onPressed: _isRecording ? _stopRecording : _startRecording,
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Color(0xFF007AFF)),
            onPressed: () {
              // 执行相机功能
            },
          ),
        ],
      ),
    );
  }
}

// * 以下是规划页面的代码
class PlanningPage extends StatelessWidget {
  const PlanningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("规划"),
      ),
      body: const DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: "日"),
                Tab(text: "月"),
              ],
              indicatorColor: Colors.blue,
            ),
            Expanded(
              child: TabBarView(
                physics: NeverScrollableScrollPhysics(),
                children: [
                  DayView(),
                  StartPage(),
                ], // 禁用滑动切换
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// * 以下是日视图的代码
class DayView extends StatefulWidget {
  const DayView({super.key});

  @override
  _DayViewState createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
  List<TimePlannerTask> tasks = [];
  List<TimePlannerTitle> headers = [
    const TimePlannerTitle(
      date: "3/11/2021",
      title: "Monday",
    ),
    const TimePlannerTitle(
      date: "3/12/2021",
      title: "Tuesday",
    ),
    const TimePlannerTitle(
      date: "3/10/2021",
      title: "Sunday",
    ),
    const TimePlannerTitle(
      date: "3/11/2021",
      title: "Monday",
    ),
    const TimePlannerTitle(
      date: "3/12/2021",
      title: "Tuesday",
    ),
    const TimePlannerTitle(
      date: "3/10/2021",
      title: "Sunday",
    ),
    const TimePlannerTitle(
      date: "3/10/2021",
      title: "Sunday",
    ),
  ]; // 存储 header 列表

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    // 替换为你的 API 端点
    final response =
        await http.get(Uri.parse('http://47.115.151.97:6201/weekItems/'));

    if (response.statusCode == 200) {
      // 使用 UTF-8 解码响应的字节
      var decodedResponse = utf8.decode(response.bodyBytes);

      // 然后将解码后的字符串解析为 JSON
      Map<String, dynamic> jsonResponse = json.decode(decodedResponse);
      List<dynamic> data = jsonResponse['data'];
      // print(data);

      List<TimePlannerTask> fetchedTasks = [];
      List<TimePlannerTitle> fetchedHeaders = []; // 存储 header 的列表

      for (var item in data.asMap().entries) {
        int index = item.key; // 获取索引
        var value = item.value; // 获取实际的 item
        String dateStr = value['date']['date'];
        String titleStr = value['date']['title'];

        // 添加 header
        fetchedHeaders.add(TimePlannerTitle(date: dateStr, title: titleStr));

        for (var task in value['tasks']) {
          fetchedTasks.add(TimePlannerTask(
            color: Colors.purple, //(task['color']), // 根据你的需求调整颜色
            dateTime: TimePlannerDateTime(
                day: index,
                hour: task['hour'],
                minutes: task['minute']), // 从 JSON 获取日期时间
            minutesDuration: task['minutesDuration'], // 从 JSON 获取持续时间
            onTap: () {},
            child: Text(
              task['textTitle'],
              style: TextStyle(color: Colors.grey[350], fontSize: 12),
            ),
          ));
        }
      }

      setState(() {
        tasks = fetchedTasks; // 更新任务列表并重建 UI
        headers = fetchedHeaders.toSet().toList(); // 使用去重的 headers 列表
        // print(headers);
      });
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TimePlanner(
        startHour: 6,
        endHour: 23,
        headers: headers, // 使用 headers 列表
        tasks: tasks,
      ),
    );
  }
}

// * 月视图 旧代码
class MonthView extends StatelessWidget {
  const MonthView({super.key});

  @override
  Widget build(BuildContext context) {
    var selectedDay = DateTime.now();
    return Scaffold(
      body: TableCalendar(
        firstDay: DateTime.utc(2010, 10, 16), // 使用冒号而不是等号
        lastDay: DateTime.utc(2030, 3, 14), // 使用冒号而不是等号
        focusedDay: DateTime.now(), // 使用冒号而不是等号
      ),
    );
  }
}

// * 以下是记事页面的代码
class NotePage2 extends StatelessWidget {
  final List<Map<String, String>> records;

  NotePage2({super.key})
      : records = [
          {
            'date': '2023-06-01',
            'location': '家里',
            'description': '开始学习新语言',
            'status': '已完成',
            'details': '今天开始学习Python，感觉非常有趣。',
            'image': 'https://example.com/python-book.jpg'
          },
          {
            'date': '2023-06-02',
            'location': '公园',
            'description': '晨跑5公里',
            'status': '已完成',
            'details': '今天的晨跑感觉很棒，天气很好，遇到了几只可爱的小狗。',
            'image': 'https://example.com/morning-run.jpg'
          },
          {
            'date': '2023-06-03',
            'location': '图书馆',
            'description': '阅读新书',
            'status': '已完成',
            'details': '读完了《百年孤独》，真是一本令人深思的好书。',
            'image': 'https://example.com/book-cover.jpg'
          },
          {
            'date': '2023-06-04',
            'location': '咖啡店',
            'description': '与朋友聚会',
            'status': '已完成',
            'details': '和多年未见的老朋友小明聚会，聊了很多近况，感觉很开心。',
            'image': 'https://example.com/coffee-meeting.jpg'
          },
          {
            'date': '2023-06-05',
            'location': '办公室',
            'description': '完成项目报告',
            'status': '已完成',
            'details': '终于完成了这个月的项目报告，松了一口气。',
            'image': 'https://example.com/project-report.jpg'
          },
          {
            'date': '2023-06-06',
            'location': '健身房',
            'description': '力量训练',
            'status': '已完成',
            'details': '今天的力量训练很充实，感觉自己又强壮了一点。',
            'image': 'https://example.com/gym-training.jpg'
          },
          {
            'date': '2023-06-07',
            'location': '电影院',
            'description': '观看新电影',
            'status': '已完成',
            'details': '看了最新的科幻电影，特效很棒，剧情也很吸引人。',
            'image': 'https://example.com/movie-poster.jpg'
          }

          // 继续添加更多记录项...
        ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("记事"),
      ),
      body: ListView(
        children: records.map<Widget>((record) {
          return ExpansionTile(
            title: Text(record['description']!),
            subtitle: Text(record['date']!),
            children: <Widget>[
              ListTile(
                title: Text("地点: ${record['location']!}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("状态: ${record['status']!}"),
                    const SizedBox(height: 10),
                    const Text("详细信息:"),
                    Text(record['details']!),
                    if (record['image']!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Image.network(record['image']!),
                      ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class NotePage extends StatefulWidget {
  const NotePage({super.key});

  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  List<Map<String, dynamic>> records = [];
  bool _isLoading = true;

  final Color blueColor = const Color(0xFFA5DFF9);
  final Color redColor = const Color(0xFFEF5285);
  final Color greenColor = const Color(0xFF60C5BA);
  final Color yellowColor = Colors.purple;
  // final Color greyColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    try {
      final response = await http
          .get(Uri.parse('http://47.115.151.97:6201/api/record/get_multi'));

      if (response.statusCode == 200) {
        Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes));
        List<dynamic> recordsData = data['data'];

        //   {
        //   "id": "PpujaZ6SSyr",
        //   "record_time": "2024-08-18T16:48:34",
        //   "record_location_name": "重庆市南岸区正街社区",
        //   "record_location": "29.533416,106.56795",
        //   "target_time": "2024-08-19T16:00:00",
        //   "target_location_name": "洪崖洞",
        //   "target_location": "29.562117,106.578757",
        //   "finish_time": "2024-08-19T16:15:00",
        //   "wake_time": "2024-08-19T15:00:00",
        //   "wake_location_name": "洪崖洞",
        //   "wake_location": "29.562117,106.578757",
        //   "record_descrpt": "我要去洪崖洞",
        //   "record_status": false
        // },
        List<Map<String, dynamic>> parsedRecords =
            recordsData.map<Map<String, dynamic>>((item) {
          return {
            'record_time':
                _removeLastTwoChars(item['record_time']?.replaceAll('T', ' ')),
            'target_time':
                _removeLastTwoChars(item['target_time']?.replaceAll('T', ' ')),
            'finish_time':
                _removeLastTwoChars(item['finish_time']?.replaceAll('T', ' ')),
            'wake_time':
                _removeLastTwoChars(item['wake_time']?.replaceAll('T', ' ')),
            'record_descrpt': item['record_descrpt'],
            'record_status': item['record_status'],
            'target_location': item['target_location'],
            'target_location_name': item['target_location_name'],
            'wake_location': item['wake_location'],
            'wake_location_name': item['wake_location_name'],
            'record_location': item['record_location'],
            'record_location_name': item['record_location_name'],
          };
        }).toList();

        setState(() {
          records = _processRecords(parsedRecords);
          _isLoading = false;
        });
      } else {
        _loadMockData();
      }
    } catch (e) {
      _loadMockData();
    }
  }

// Helper function to remove the last two characters from a string
  String _removeLastTwoChars(String? input) {
    if (input == null || input.length < 3) {
      return input ?? '';
    }
    return input.substring(0, input.length - 3);
  }

  void _loadMockData() {
    final mockData = [
      {
        'record_time': '2024-08-14 00:02:42',
        'target_time': '2024-08-14 08:00:00',
        'finish_time': '2024-08-14 09:00:00',
        'wake_time': '2024-08-14 07:00:00',
        'record_descrpt': '在2024年8月14日 08:00:00时与金主爸爸讨论人生',
        'record_status': false
      },
    ];

    setState(() {
      records = _processRecords(mockData);
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _processRecords(
      List<Map<String, dynamic>> records) {
    final now = DateTime.now();
    records.sort((a, b) {
      DateTime? dateA =
          a['target_time'] != null ? DateTime.tryParse(a['target_time']) : null;
      DateTime? dateB =
          b['target_time'] != null ? DateTime.tryParse(b['target_time']) : null;

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      if (dateA.isBefore(now) && dateB.isBefore(now)) {
        return dateA.compareTo(dateB);
      } else if (dateA.isBefore(now)) {
        return 1;
      } else if (dateB.isBefore(now)) {
        return -1;
      } else {
        return dateA.compareTo(dateB);
      }
    });

    return records;
  }

  // Color _getItemColor(DateTime? targetDate, bool status) {
  //   final now = DateTime.now();
  //   final twoDaysLater = now.add(const Duration(hours: 48));
  //   final oneWeekLater = now.add(const Duration(hours: 168));

  //   if (status) {
  //     return greenColor;
  //   } else if (targetDate == null) {
  //     return blueColor;
  //   } else if (targetDate.isBefore(now)) {
  //     return greyColor;
  //   } else if (targetDate.isBefore(twoDaysLater)) {
  //     return redColor;
  //   } else if (targetDate.isBefore(oneWeekLater)) {
  //     return yellowColor;
  //   } else {
  //     return blueColor;
  //   }
  // }

  Color _getItemColor(DateTime? targetDate, bool status) {
    final now = DateTime.now();
    final twoDaysLater = now.add(const Duration(hours: 48));
    final oneWeekLater = now.add(const Duration(hours: 168));

    if (status) {
      return greenColor;
    } else if (targetDate == null) {
      return blueColor;
    } else if (targetDate.isBefore(now)) {
      return blueColor;
    } else if (targetDate.isBefore(twoDaysLater)) {
      return redColor;
    } else if (targetDate.isBefore(oneWeekLater)) {
      return yellowColor;
    } else {
      return blueColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("记事"),
        // backgroundColor: blueColor,
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                final targetDate = record['target_time'] != null
                    ? DateTime.tryParse(record['target_time'])
                    : null;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  color: _getItemColor(targetDate, record['record_status']),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      record['record_descrpt'],
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      record['target_time'] ?? '无',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    children: <Widget>[
                      ListTile(
                        title: Text(
                          "目标时间: ${record['target_time'] ?? '无'} 地点：${record['target_location_name'] ?? '无'}",
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "目标坐标: ${record['target_location'] ?? '无'}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "唤醒时间: ${record['wake_time'] ?? '无'} 地点：${record['wake_location_name'] ?? '无'}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "唤醒坐标: ${record['wake_location'] ?? '无'}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "结束时间: ${record['finish_time'] ?? '无'}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "记录时间: ${record['record_time']} 坐标：${record['record_location'] ?? '无'}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// * 月视图
class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: TableEventsExample());
  }
}
