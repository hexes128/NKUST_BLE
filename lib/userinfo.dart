
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:intl/intl.dart';

class userinfo extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return userinfostate();
  }
}

class userinfostate extends State<userinfo> {

  final storage =  const FlutterSecureStorage();
savadata() async{
  // await storage.write(key: 'stuid', value: 'F108154158');
  // await storage.write(key: 'phone', value: 'ff09101234444444');
  // await storage.write(key: 'name', value: 'wunshuai');
  await storage.deleteAll();
}
  @override
  initState() {
    savadata();

    super.initState();

  }
  @override
  Widget build(BuildContext context) {
    return


     FutureBuilder<Map<String, String>>(
        future: storage.readAll(),
        initialData:null,
        builder: (BuildContext context, AsyncSnapshot<Map<String, String>> snapshot) {
          if (snapshot.hasData&& snapshot.data!.isNotEmpty) {
            return Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: AppBar(
                  title: Text('個人資訊'),
                ),
                body: SingleChildScrollView(
                    child: Column(
                      children: [
                        Card(
                          child: ListTile(
                            title: Text('姓名'),
                            subtitle: Text(snapshot.data!['stuid'].toString()),
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text('電話'),
                            subtitle: Text(snapshot.data!['name'].toString()),
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text('信箱'),
                            subtitle: Text(snapshot.data!['phone'].toString()),
                          ),
                        ),
                        Card(
                            child: ListTile(
                                title: Text('美簽到期日'),
                                subtitle: Text(snapshot.data!['phone'].toString()))),
                        Card(
                          child: ListTile(
                            title: Text('美簽剩餘天數'),
                            subtitle: Text(snapshot.data!['phone'].toString()),
                          ),
                        ),
                      ],
                    )));

          } else {
return Text('等待');
          }
        });
  }
}
