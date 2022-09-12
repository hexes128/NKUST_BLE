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



Map<BluetoothCharacteristic,List<List<int>> >btdata={};
  Future<void> discoverservice(BluetoothDevice device) async {
    await device.discoverServices();
  }

  Future<void> setnotify(BluetoothCharacteristic chara) async {
    try {
      if(!chara.isNotifying){
        await chara.setNotifyValue(true);
   btdata[chara]=[];
      }

    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return

      FutureBuilder<List<BluetoothDevice>>(
        future:FlutterBlue.instance.connectedDevices,
          // Stream.periodic(const Duration(seconds: 1)).asyncMap((_) => FlutterBlue.instance.connectedDevices),
        initialData: [],
        builder: (c, snapdevice) {
          if (snapdevice.data!.isNotEmpty) {

            return
              DefaultTabController(length: snapdevice.data!.length, child: Scaffold(
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
                              deviceindex = 0;
                            }));
                          },
                          icon: const Icon(Icons.search)),
                    ],
                  ),
                  body: TabBarView(

                    children: snapdevice.data!
                        .map(
                          (device) {
                      
                            return
                            SingleChildScrollView(
                              child: Column(
                                children: <Widget>[
                                  StreamBuilder<BluetoothDeviceState>(
                                      stream: device!.state,
                                      initialData: BluetoothDeviceState.disconnecting,
                                      builder: (c, snapstate) {
                                        print(snapstate.data);

                                        if(    snapstate.data == BluetoothDeviceState.connected ||snapstate.data == BluetoothDeviceState.disconnecting){
                                          return Column(children: [
                                            ListTile(
                                              leading: Icon(snapstate.data == BluetoothDeviceState.connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled),
                                              title: Text(device!.name + '${snapstate.data.toString().split('.')[1]}.'),
                                              subtitle: Text('${device!.id}'),
                                            ),


                                            StreamBuilder<List<BluetoothService>>(
                                                stream: device.services,
                                                initialData: [],
                                                builder: (c, snapservice) {
                                                  if (snapservice.data!.isNotEmpty) {


                                                    if (btdata.keys.map((e) => e.deviceId.id).contains(device.id.id)) {
                                                      BluetoothCharacteristic chara=btdata.keys.where((x) => x.deviceId.id==device.id.id).first;
                                                      return StreamBuilder<List<int>>(
                                                          stream:btdata.keys.where((x) => x.deviceId.id==device.id.id).first .value,
                                                          initialData: [],
                                                          builder: (c, snapvalue) {
                                                            if(snapvalue.data!.isNotEmpty){
                                                              btdata[chara]!.insert(0, snapvalue.data!);
                                                            }

                                                            return ListView(
                                                              shrinkWrap: true,
                                                              children:  btdata[chara]!
                                                                  .map((e) => Card(
                                                                child: ListTile(
                                                                  title: Text('$e'),
                                                                ),
                                                              ))
                                                                  .toList(),
                                                            );
                                                          });
                                                    } else {
                                                      BluetoothService service = snapservice.data!.singleWhere((e) => e.uuid.toString() == '0000ffe0-0000-1000-8000-00805f9b34fb');
                                                      BluetoothCharacteristic chara = service.characteristics.singleWhere((e) => e.uuid.toString() == '0000ffe1-0000-1000-8000-00805f9b34fb');
                                                      setnotify(chara);
                                                      return Container();
                                                    }

                                                  } else {
                                                    discoverservice(device);
                                                    return Container();
                                                  }
                                                })

                                          ]);
                                        }
                                        else if( snapstate.data == BluetoothDeviceState.disconnected){
                                          btdata.removeWhere((key, value) => key.deviceId.id==device.id.id);
                                          return Container();
                                        }
                                        else{
                                          return Container();
                                        }


                                      }),
                                ],
                              ),
                            );
                            }

                    )
                        .toList(),
                  ),

                  bottomNavigationBar: Material(
                      color: Theme.of(context).primaryColor,
                      child: TabBar(

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
                                  initialData: BluetoothDeviceState.connecting,
                                  builder: (c, state) {
                                    return Text(e.name + '${state.data.toString().split('.')[1]}.');
                                  },
                                ),
                              ),
                            ),
                          )
                              .toList()))));
              ;
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
                              deviceindex = 0;
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

  // Future<void> discoverservice(BluetoothDevice? device) async {
  //   if (!btdata.keys.contains(device!.id.id)) {
  //     await device!.discoverServices().then((servicelist) async {
  //       BluetoothService service = servicelist.singleWhere((e) => e.uuid.toString() == '0000ffe0-0000-1000-8000-00805f9b34fb');
  //
  //       BluetoothCharacteristic chara = service.characteristics.singleWhere((e) => e.uuid.toString() == '0000ffe1-0000-1000-8000-00805f9b34fb');
  //       try {
  //         await chara.setNotifyValue(true);
  //         btdata[device.id.id] = [];
  //         if (!Subscriptions.keys.contains(device.id.id)) {
  //           Subscriptions[device!.id.id] = chara.value.listen((event) {
  //             if (event.isNotEmpty) {
  //               setState(() {
  //                 btdata[device!.id.id]!.insert(0, event);
  //               });
  //             }
  //           });
  //         }
  //       } catch (e) {}
  //     });
  //   }
  // }
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
