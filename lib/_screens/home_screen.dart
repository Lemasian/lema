import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart';
import 'package:leap/_screens/chapter_list_screen.dart';
import 'package:leap/_screens/createprofile_screen.dart';
import 'package:leap/_screens/grammar_list_screen.dart';
import 'package:leap/_screens/home_list_first_screen.dart';
import 'package:leap/_screens/home_list_admin_screen.dart';
import 'package:leap/_screens/signin_screen.dart';
import 'package:leap/api.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../app_theme.dart';
import '../navbar.dart';
import '../providers/storage.dart';
import 'grid_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  double marginHorizontal = 16.0;

  final userStorage = StorageProvider().userStorage();
  final commonDataStorage = StorageProvider().commonDataStorage();
  late var user_id;

  late var userDetails = {};
  late var chapterLists = [];
  late var topicLists = [];
  late var leaderboardsLists = [];
  late var topicWithScore = [];
  late var _isloading = false;
  late var overallScore = 0;
  late double grammar_percentage = 0.0;
  late var total_users = 0;
  late double lessons_overall_percentage = 0.0;
  late var dashboardData = [];
  late var adminDashboardData = [];

  var rankCount = 0;
  var rankScore = "";

  List<Widget> listViews = <Widget>[];
  final ScrollController scrollController = ScrollController();
  AnimationController? animationController;

  calcPercentage() {
    var percentage = (topicWithScore.length / topicLists.length);
    grammar_percentage = percentage;
    homeListsView();
  }

  calculateLessonsUsage(data) {
    double perc = 0.0;
    double overall_perc = 0.0;
    for(var user in data){
      perc += user['topics_done'] / topicLists.length;
    }
    overall_perc = perc / total_users;
    setState(() {
      lessons_overall_percentage = overall_perc;
    });
  }

  getData() async {
    setState(() {
      grammar_percentage = 0;
      overallScore = 0;
      total_users = 0;
    });
    var urls = [
      'chapters/all', // 0
      'topics/all', // 1
      'user_topics_detailed/${userDetails['id']}', // 2
      'users_count', // 3
      'users_with_topics_done', // 4
      'leaderboards_lists/all', // 5
      'get_user_dashboard_data/${userDetails['id']}',
      'get_admin_dashboard_data' // 7
    ];
    var datas = await Api().multipleGetRequest(urls);

    setState(() {
      adminDashboardData = datas[7];
      dashboardData = datas[6];
      leaderboardsLists = datas[5];

      for(var x=0; x<leaderboardsLists.length; x++){
        print('=====================');
        print(leaderboardsLists[x]['id']);
        print(userDetails['id']);
        if(userDetails['id'] == leaderboardsLists[x]['id']){
          rankCount = x+1;
          rankScore = leaderboardsLists[x]['score'];
        }
      }

      setChapterList(datas[0]);
      setTopicList(datas[1]);
      setTopicWithScore(datas[2]);
      total_users = datas[3]['users_count'] ?? 0;
      calcPercentage();
      calculateLessonsUsage(datas[4]);

      print('datas[6] ${datas[6]}');
      _isloading = false;
    });
  }

  setUserDetails(details) async {
    if(details == null || details == []){
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const SignInScreen()), (route) => false );
    } else {
      await StorageProvider().storageRemoveItem(userStorage, 'user_details');
      await StorageProvider().storageAddItem(userStorage, 'user_details', jsonEncode(details));
    }

    setState(() {
      userDetails = details;
      getData();
    });
  }

  setChapterList(chapters) {
    chapterLists = chapters;
  }

  setTopicList(topics) {
    topicLists = topics;
  }

  setTopicWithScore(topicWithScores) {
    var mytopics = [];
    var scores = 0;
    for(var topic in topicWithScores){
      if(topic['user_id'] == userDetails['id']){
        mytopics.add(topic);
        var sc = topic['score'];
        scores = scores + sc as int;
      }
    }
    topicWithScore = mytopics;
    overallScore = scores;
  }

  Future _initRetrieval() async {
    listViews = <Widget>[];


    user_id = await StorageProvider().storageGetItem(userStorage, 'user_id');
    setState(() {
      _isloading = true;
    });
    setUserDetails(await Api().getRequest('users/$user_id'));
  }

  @override
  void initState() {
    animationController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    super.initState();
    _initRetrieval();
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

  void homeListsView() {
    const int count = 7;
    listViews.add(
        const SizedBox(height: 20)
    );
    listViews.add(
        Padding(
        padding: EdgeInsets.only(
          left: 18.0,
          right: 16.0,// Add animation to the bottom padding
        ),
        child: Opacity(
          opacity: 1, // Add animation to the opacity
          child: Text(
            userDetails['role_id'] == 0 ? 'Learning Usage' : 'Learning Performance',
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
              letterSpacing: 0.27,
              color: AppTheme.darkerText,
            ),
          ),
        ),
      )
    );

    if(userDetails['role_id'] == 0){
      listViews.add(
        HomeListAdminScreen(
          animation: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation( parent: animationController!, curve: const Interval((1 / count) * 1, 1.0, curve: Curves.fastOutSlowIn))),
          animationController: animationController!,
          dashboardData: adminDashboardData
        )
      );
    } else {
      listViews.add(
        HomeListFirstScreen(
          animation: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation( parent: animationController!, curve: const Interval((1 / count) * 1, 1.0, curve: Curves.fastOutSlowIn))),
          animationController: animationController!,
          grammarPercentage: grammar_percentage,
          dashboardData: dashboardData,
          totalUsers: total_users,
          rank: rankCount,
          rankScore: rankScore
        )
      );
    }
    listViews.add(
      const Padding(
        padding: EdgeInsets.only(
          left: 18.0,
          right: 16.0,// Add animation to the bottom padding
        ),
        child: Opacity(
          opacity: 1, // Add animation to the opacity
          child: Text(
            'Chapters',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
              letterSpacing: 0.27,
              color: AppTheme.darkerText,
            ),
          ),
        ),
      )
    );

    listViews.add(
      getCategoryUI()
    );

    listViews.add(
      const Padding(
        padding: EdgeInsets.only(
          left: 18.0,
          right: 16.0,// Add animation to the bottom padding
        ),
        child: Opacity(
          opacity: 1, // Add animation to the opacity
          child: Text(
            'Top 3 User Leaderboards',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
              letterSpacing: 0.27,
              color: AppTheme.darkerText,
            ),
          ),
        ),
      )
    );

    listViews.add(
        const SizedBox(height: 20)
    );

    var indexing = 1;
    int limit = 3;
    for (var item in leaderboardsLists) {
      listViews.add(
        Padding(
          padding: const EdgeInsets.only(
            left: 18.0,
            right: 16.0,// Add animation to the bottom padding
          ),
          child: Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: (userDetails['id'] == item['id']) ? AppTheme.teal : AppTheme.salmon,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            elevation: (userDetails['id'] == item['id']) ? 5 : 3,
            child: ListTile(
              title: (userDetails['id'] == item['id']) ? const Text('You') : Text("${item['first_name']} ${item['last_name']}"),
              trailing: Text("${item['score']}"),
              leading: SizedBox(
                width: 30,
                height: 30,
                child: Image.asset('assets/leaderboards_image/$indexing.png'),
              ),
            ),
          ),
        ),
      );
      if (indexing >= limit) {
        break; // Exit the loop once the limit is reached
      }
      indexing++;
    }
    //leaderboardsLists
  }


  Widget getMainListViewUI() {
    return ListView.builder(
      controller: scrollController,
      itemCount: listViews.length,
      scrollDirection: Axis.vertical,
      itemBuilder: (BuildContext context, int index) {
        animationController?.forward();
        return listViews[index];
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      centerTitle: true,
      title: Text(
        'LEMA',
        style: TextStyle(color: Theme.of(context).primaryColor),
      ),
      elevation: 0,
      backgroundColor: AppTheme.beige,
      shadowColor: Colors.white,
      iconTheme: IconThemeData(
        color: Theme.of(context).primaryColor,
      ),
    ),
    body: RefreshIndicator(
      onRefresh: () async {
        _initRetrieval();
      },

      child: Container(
        color: AppTheme.beige,
        child: Stack(
          children: <Widget>[
            getMainListViewUI(),
          ],
        ),
      ),
    ),

  );


  Widget getCategoryUI() {
    final Animation<double> animation =
    Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: animationController!,
            curve: const Interval(1.0, 1.0,
                curve: Curves.fastOutSlowIn)));
    animationController?.forward();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ChapterListScreen(
          callBack: (category) {
            moveTo(category);
          },
          chapters: chapterLists
        ),
      ]
    );
  }

  Widget getTopicUi() {
    final Animation<double> animation =
    Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: animationController!,
            curve: const Interval(1.0, 1.0,
                curve: Curves.fastOutSlowIn)));
    animationController?.forward();

    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Flexible(
            child: GridList(
              callBack: (category) {
                moveTo(category);
              },
            ),
          )
        ]
    );
  }

  void moveTo(list) {
    print(list);
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => GrammarListScreen(chapter: list)), (route) => true );
  }
}