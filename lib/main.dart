import 'package:flutter/material.dart';
import 'package:nkust_ble/BLE_controlpanel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WNMC_BLE',
      theme: ThemeData(

        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: '國立高雄科技大學 電機工程系'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);



  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
 var arr=    ['藍芽MCU儀表板', '個人資料','關於本APP','...'];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body:


      GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 2.5),
          itemCount: arr.length,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              child: Card(
                color: Colors.amber,
                child: Center(child: Text(arr[index])),
              ),
              onTap: () {
                switch (arr[index]) {
                  case('藍芽MCU儀表板'):{
                    Navigator.push(
                      //從登入push到第二個
                      context,
                      MaterialPageRoute(
                          builder: (context) => ble_controlpanel()),
                    );
                    break;
                  }
                }
              },
            );
          }),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
