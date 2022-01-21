import 'dart:math';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nkust_ble/widgets.dart';
import 'global.dart' as GV;
class scanpage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BluetoothState>(
        stream: FlutterBlue.instance.state,
        initialData: BluetoothState.unknown,
        builder: (c, snapshot) {
          final state = snapshot.data;
          if (state == BluetoothState.on) {
            return FindDevicesScreen();
          }
          return BluetoothOffScreen(state: state);
        });
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key? key, this.state}) : super(key: key);

  final BluetoothState? state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
            ),
          ],
        ),
      ),
    );
  }
}

class FindDevicesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Devices'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<List<BluetoothDevice>>(
              stream: Stream.periodic(const Duration(seconds: 1))
                  .asyncMap((_) => FlutterBlue.instance.connectedDevices),
              initialData: [],
              builder: (c, snapshot) => Column(
                children: snapshot.data!
                    .map((d) => ListTile(
                          title: Text(d.name),
                          subtitle: Text(d.id.toString()),
                          trailing: StreamBuilder<BluetoothDeviceState>(
                            stream: d.state,
                            initialData: BluetoothDeviceState.disconnected,
                            builder: (c, snapshot) {
                              if (snapshot.data ==
                                  BluetoothDeviceState.connected) {
                                return RaisedButton(
                                  child: const Text('開啟控制板'),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                DeviceScreen(device: d)));
                                  },
                                );
                              }
                              return Text(snapshot.data.toString());
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
            StreamBuilder<List<ScanResult>>(
                stream: FlutterBlue.instance.scanResults,
                initialData: [],
                builder: (c, snapshot) {
                  // snapshot.data!.sort((a,b)=>b.advertisementData.connectable?1:-1);
                  // snapshot.data!.sort((a,b)=>a.device.name.compareTo(b.device.name));
                  return Column(
                    children: snapshot.data!
                        .where((e) => e.advertisementData.connectable)
                        .map(
                          (r) => ScanResultTile(
                              result: r,
                              onTap: () {
                                r.device.connect();
                              }),
                        )
                        .toList(),
                  );
                }),
          ],
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.search),
                onPressed: () => FlutterBlue.instance
                    .startScan(timeout: Duration(seconds: 3)));
          }
        },
      ),
    );
  }
}
class DeviceScreen extends StatefulWidget{
  final BluetoothDevice device;
  DeviceScreen({Key? key, required this.device}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
return DeviceScreenstate();
  }
}
class DeviceScreenstate extends State<DeviceScreen> {



bool showterminal = true;
  List<Widget> _buildServiceTiles(List<BluetoothService> services) {


    return services
        .map(
          (s) => ServiceTile(
            service: s,
            characteristicTiles: s.characteristics
                .map(
                  (c) => CharacteristicTile(
                    characteristic: c,
                    onReadPressed: () => c.read(),
                    onWritePressed: () async {
                      await c.write([0x00, 0x01, 0x02]);
                      await c.read();
                    },
                    onNotificationPressed: () async {
                      if (!c.isNotifying) {
                        await c.setNotifyValue(true);
                      }
                    },
                    // descriptorTiles: c.descriptors
                    //     .map(
                    //       (d) => DescriptorTile(
                    //         descriptor: d,
                    //         onReadPressed: () => d.read(),
                    //         onWritePressed: () => d.write(_getRandomBytes()),
                    //       ),
                    //     )
                    //     .toList(),
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }
setnotify(BluetoothCharacteristic chara) async{

    if(! chara.isNotifying){
      await chara.setNotifyValue(true);
    }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ListTile(title: Text(widget.device.name) ,
        subtitle:  Text(GV.arr[GV.receivemode])),


        actions: <Widget>[
          StreamBuilder<BluetoothDeviceState>(
            stream:widget.device.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) {
              VoidCallback? onPressed;
              String text;
              switch (snapshot.data) {
                case BluetoothDeviceState.connected:
                  onPressed = () =>widget. device.disconnect();
                  text = 'DISCONNECT';
                  widget.   device.discoverServices();
                  break;
                case BluetoothDeviceState.disconnected:
                  onPressed = () => widget.device.connect();
                  text = 'CONNECT';
                  break;
                default:
                  onPressed = null;
                  text = snapshot.data.toString().substring(21).toUpperCase();
                  break;
              }
              return FlatButton(
                  onPressed: onPressed,
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .primaryTextTheme
                        .button
                        ?.copyWith(color: Colors.white),
                  ));
            },
          ),

        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<BluetoothDeviceState>(
              stream:widget. device.state,
              initialData: BluetoothDeviceState.connecting,
              builder: (c, snapshot) => ListTile(
                leading: (snapshot.data == BluetoothDeviceState.connected)
                    ? Icon(Icons.bluetooth_connected)
                    : Icon(Icons.bluetooth_disabled),
                title: Text(
                    'Device is ${snapshot.data.toString().split('.')[1]}.'),
                subtitle: Text('${widget.device.id}'),
                trailing: StreamBuilder<bool>(
                  stream:widget. device.isDiscoveringServices,
                  initialData: false,
                  builder: (c, snapshot) => IndexedStack(
                    index: snapshot.data! ? 1 : 0,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: () => widget.device.discoverServices(),
                      ),
                      const IconButton(
                        icon: SizedBox(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.grey),
                          ),
                          width: 18.0,
                          height: 18.0,
                        ),
                        onPressed: null,
                      )
                    ],
                  ),
                ),
              ),
            ),
            StreamBuilder<List<BluetoothService>>(
              stream:widget. device.services,
              initialData: const [],
              builder: (c, snapshot) {
                if (snapshot.data!.isNotEmpty) {
                  BluetoothService service = snapshot.data!.singleWhere((e) =>
                  e.uuid.toString() ==
                      '0000ffe0-0000-1000-8000-00805f9b34fb');

                  BluetoothCharacteristic chara = service.characteristics
                      .singleWhere((e) =>
                  e.uuid.toString() ==
                      '0000ffe1-0000-1000-8000-00805f9b34fb');
setnotify(chara);

                  return Column(
                    children: _buildServiceTiles(snapshot.data!
                        .where((e) =>
                    e.uuid.toString() ==
                        '0000ffe0-0000-1000-8000-00805f9b34fb')
                        .toList()),
                  );





                }
                return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Text(
                            '資料讀取中',
                            style: Theme.of(context).textTheme.headline6,
                          ),
                          const CircularProgressIndicator(),
                        ],
                      ),
                    ));
              },
            ),
          ],
        ),
      ),
    );
  }
}
