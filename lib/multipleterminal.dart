import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:hex/hex.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nkust_ble/scanpage.dart';
import 'package:flutter_blue/flutter_blue.dart';

class terminal extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return terminalstate();
  }
}

class terminalstate extends State<terminal> with TickerProviderStateMixin {
  TabController? tabController;
  int deviceindex = 0;
  BluetoothDevice? device;

  Map<String, StreamSubscription> Subscriptions = {};
  Map<String, List<btdata>> btdataList = {};






  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BluetoothDevice>>(
        stream: Stream.periodic(const Duration(seconds: 1))
            .asyncMap((_) => FlutterBlue.instance.connectedDevices),
        initialData: [],
        builder: (c, snapdevice) {
          if (snapdevice.data!.isNotEmpty) {
            try {
              tabController = TabController(
                  length: snapdevice.data!.length,
                  vsync: this,
                  initialIndex: deviceindex);
              device = snapdevice.data![deviceindex];
              tabController!.addListener(() {
                if (tabController!.indexIsChanging) {
                  setState(() {
                    deviceindex = tabController!.index;
                  });
                }
              });
            } catch (e) {}

            return Scaffold(
                appBar: AppBar(
                  title: const Text('Terminal'),
                  actions: [
                    IconButton(
                        onPressed: () {
                          Navigator.push(
                            //從登入push到第二個
                            context,
                            MaterialPageRoute(builder: (context) => scanpage()),
                          ).then((value) => setState(() {
                            deviceindex=0;

                          }));
                        },
                        icon: const Icon(Icons.search)),
                  ],
                ),
                body: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      StreamBuilder<BluetoothDeviceState>(
                          stream: device!.state,
                          initialData: BluetoothDeviceState.connecting,
                          builder: (c, snapstate) {
                            switch (snapstate.data) {
                              case (BluetoothDeviceState.connected):
                                {
                                  discoverservice(device);

                                  break;
                                }
                              case (BluetoothDeviceState.disconnected):
                                {
                                  if(btdataList.keys.contains(device!.id.id)){
                                    btdataList.remove(device!.id.id);
                                    Subscriptions[device!.id.id]!.cancel();
                                    Subscriptions.remove(device!.id.id);
                                  }


                                  break;
                                }
                            }

                            return Column(children: [
                              ListTile(
                                  leading: Icon(snapstate.data ==
                                      BluetoothDeviceState.connected
                                      ? Icons.bluetooth_connected
                                      : Icons.bluetooth_disabled),
                                  title: Text(device!.name +
                                      '${snapstate.data.toString().split('.')[1]}.'),
                                  subtitle: Text('${device!.id}'),
                            ),
                              btdataList.keys.contains(device!.id.id)
                                  ? SingleChildScrollView(
                                child: SizedBox(
                                  height: 700,
                                  child: ListView(
                                    shrinkWrap: true,
                                    children:
                                    btdataList[device!.id.id]!.map((e) {
                                      return Card(
                                        child: ListTile(
                                          title: Text('${e.receivedata}'+'\n'+latin1.decode( e.receivedata).trim()),
                                          subtitle: Text(e.receivetime),

                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              )
                                  : Container()
                            ]);
                          }),
                    ],
                  ),
                ),
                bottomNavigationBar: Material(
                    color: Theme.of(context).primaryColor,
                    child: TabBar(
                        controller: tabController,
                        indicatorColor: Colors.red,
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.white,
                        isScrollable: true,
                        tabs: snapdevice.data!
                            .map(
                              (e) => SizedBox(
                            child: Tab(
                              child: StreamBuilder<BluetoothDeviceState>(
                                stream: e.state,
                                initialData:
                                BluetoothDeviceState.connecting,
                                builder: (c, state) {
                                  return Text(e.name +
                                      '${state.data.toString().split('.')[1]}.');
                                },
                              ),
                            ),
                          ),
                        )
                            .toList())));
          } else {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Terminal'),
                actions: [
                  IconButton(
                      onPressed: () {
                        Navigator.push(
                          //從登入push到第二個
                          context,
                          MaterialPageRoute(builder: (context) => scanpage()),
                        ).then((value) => setState(() {
                          deviceindex=0;

                        }));
                      },
                      icon: const Icon(Icons.search)),
                ],
              ),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    Text(
                      '尚未取得任何裝置',
                    ),
                  ],
                ),
              ),
            );
          }
        });
  }

  Future<void> discoverservice(BluetoothDevice? device) async {

    if (!btdataList.keys.contains(device!.id.id)) {
      await device!.discoverServices().then((servicelist) async {
        BluetoothService service = servicelist.singleWhere(
                (e) => e.uuid.toString() == '0000ffe0-0000-1000-8000-00805f9b34fb');

        BluetoothCharacteristic chara = service.characteristics.singleWhere(
                (e) => e.uuid.toString() == '0000ffe1-0000-1000-8000-00805f9b34fb');
        try {
          await chara.setNotifyValue(true);
          btdataList[device.id.id] = [];
          if (!Subscriptions.keys.contains(device.id.id)) {
            Subscriptions[device!.id.id] = chara.value.listen((event) {
              if (event.isNotEmpty) {
                setState(() {
                  btdataList[device!.id.id]!.insert(0,btdata(event) );
                });
              }
            });
          }
        } catch (e) {}
      });
    }
  }
}

class subscriptiondata {
  StreamSubscription subscription;
  List<btdata> datalist;

  subscriptiondata(this.subscription, this.datalist);
}

class btdata {
  String receivetime = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
  List<int> receivedata;

  btdata(this.receivedata);
}
