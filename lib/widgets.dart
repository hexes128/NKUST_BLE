// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:hex/hex.dart';

class ScanResultTile extends StatelessWidget {
  const ScanResultTile({Key? key, required this.result, this.onTap})
      : super(key: key);

  final ScanResult result;
  final VoidCallback? onTap;

  Widget _buildTitle(BuildContext context) {
    if (result.device.name.length > 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            result.device.name,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            result.device.id.toString(),
            style: Theme.of(context).textTheme.caption,
          )
        ],
      );
    } else {
      return Text(result.device.id.toString());
    }
  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.caption),
          SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .caption
                  ?.apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'
        .toUpperCase();
  }

  String getNiceManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) {
      return 'N/A';
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add(
          '${id.toRadixString(16).toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  String getNiceServiceData(Map<String, List<int>> data) {
    if (data.isEmpty) {
      return 'N/A';
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add('${id.toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle(context),
      leading: Text(result.rssi.toString()),
      trailing: RaisedButton(
        child: Text('CONNECT'),
        color: Colors.black,
        textColor: Colors.white,
        onPressed: (result.advertisementData.connectable) ? onTap : null,
      ),
      children: <Widget>[
        _buildAdvRow(
            context, 'Complete Local Name', result.advertisementData.localName),
        _buildAdvRow(context, 'Tx Power Level',
            '${result.advertisementData.txPowerLevel ?? 'N/A'}'),
        _buildAdvRow(context, 'Manufacturer Data',
            getNiceManufacturerData(result.advertisementData.manufacturerData)),
        _buildAdvRow(
            context,
            'Service UUIDs',
            (result.advertisementData.serviceUuids.isNotEmpty)
                ? result.advertisementData.serviceUuids.join(', ').toUpperCase()
                : 'N/A'),
        _buildAdvRow(context, 'Service Data',
            getNiceServiceData(result.advertisementData.serviceData)),
      ],
    );
  }
}

class ServiceTile extends StatelessWidget {
  final BluetoothService service;
  final List<CharacteristicTile> characteristicTiles;

  const ServiceTile(
      {Key? key, required this.service, required this.characteristicTiles})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (characteristicTiles.length > 0) {
      return Column(
        children: [
          ListTile(
              title: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Service'),
                    Text(
                      '0x${service.uuid.toString().toUpperCase().substring(4, 8)}',
                    )
                  ])),
          Column(children: characteristicTiles)
        ],
      );
    } else {
      return ListTile(
        title: Text('Service'),
        subtitle:
        Text('0x${service.uuid.toString().toUpperCase().substring(4, 8)}'),
      );
    }
  }
}

class CharacteristicTile extends StatelessWidget {
  final BluetoothCharacteristic characteristic;

  // final List<DescriptorTile> descriptorTiles;
  final VoidCallback? onReadPressed;
  final VoidCallback? onWritePressed;

  final VoidCallback? onNotificationPressed;

  CharacteristicTile(
      {Key? key,
        required this.characteristic,
        // required this.descriptorTiles,
        this.onReadPressed,
        this.onWritePressed,
        this.onNotificationPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    characteristic.setNotifyValue(true);

    final myController = TextEditingController();
    var receiveController = TextEditingController();
    List<dynamic> features = [
      {
        'codename': '密碼',
        'value': [0x31, 0x32, 0x0d]
      },
      {
        'codename': '馬達啟動',
        'value': [0x41, 0x0d]
      },
      {
        'codename': '馬達中速',
        'value': [0x53, 0x0d]
      },
      {
        'codename': '馬達低速',
        'value': [0x44, 0x0d]
      },
      {
        'codename': '馬達停止',
        'value': [0x50, 0x0d]
      },
      {
        'codename': '時間',
        'value': [0x54, 0x0d]
      }
    ];
    return StreamBuilder<List<int>>(
      stream: characteristic.value,
      initialData: characteristic.lastValue,
      builder: (c, snapshot) {
        final value = snapshot.data;
        receiveController = TextEditingController(
            text: DateTime.now().toString() +
                '\n' +
                value.toString() +
                '\n' +
                '---------------------------------------------------------' +
                '\n' +
                receiveController.text +
                '\n');
        return Column(
          children: [
            ExpansionTile(
              title: ListTile(
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Characteristic'),
                    Text(
                      '0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}',
                    )
                  ],
                ),
                subtitle: Text(value.toString()),
                contentPadding: EdgeInsets.all(0.0),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // IconButton(
                  //   icon: Icon(
                  //     Icons.file_download,
                  //     color:
                  //         Theme.of(context).iconTheme.color?.withOpacity(0.5),
                  //   ),
                  //   onPressed: onReadPressed,
                  // ),
                  IconButton(
                    icon: Icon(Icons.delete,
                        color: Theme.of(context)
                            .iconTheme
                            .color
                            ?.withOpacity(0.5)),
                    onPressed: () {
                      receiveController.clear();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.sync,
                        color: Theme.of(context)
                            .iconTheme
                            .color
                            ?.withOpacity(0.5)),
                    onPressed: onNotificationPressed,
                  )
                ],
              ),
              // children: descriptorTiles,
            ),
            // characteristic.isNotifying
            //     ?
            SingleChildScrollView(child:  Column(
              children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(), labelText: '傳送資料'),
                        controller: myController,
                        style: TextStyle(height: 1, color: Colors.black)),
                    flex: 4,
                  ),
                  Expanded(
                    child: RaisedButton(
                      child: const Text('送出(常按以顯示特定指令)'),
                      onPressed: () async {
                        try {
                          List<int> textdata = [];
                          textdata.addAll(HEX.decode(myController.text));
                          textdata.add(0x0d);
                          await characteristic.write(textdata);

                          print(textdata);
                        } catch (e) {
                          print(e.toString());
                        }
                      }
                      ,onLongPress: (){
                      showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        // user must tap button!
                        builder: (BuildContext context) {
                          return AlertDialog(
                              title: const Text('請選擇指令'),
                              content: SizedBox(
                                  width: double.maxFinite,
                                  child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: features.length,
                                      itemBuilder: (context, index) {
                                        return

                                          Card(
                                            child: ListTile(

                                              title: Text(features[index]['codename']),
                                              onTap: ()async{
                                                await characteristic.write(features[index]['value']);
                                                Navigator.pop(context);
                                              },
                                            ),
                                          );
                                      })));
                        },
                      );

                    },
                    ),

                    flex: 1,
                  )
                ]),

                Container(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight:300,
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(), labelText: '接收資料'),
                      controller: receiveController,
                      readOnly: true,
                      maxLines: null,
                    ),
                  ),
                ),


              ],
            ))


            // : Container()
          ],
        );
      },
    );
  }
}

class DescriptorTile extends StatelessWidget {
  final BluetoothDescriptor descriptor;
  final VoidCallback? onReadPressed;
  final VoidCallback? onWritePressed;

  const DescriptorTile(
      {Key? key,
        required this.descriptor,
        this.onReadPressed,
        this.onWritePressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Descriptor'),
          Text(
            '0x${descriptor.uuid.toString().toUpperCase().substring(4, 8)}',
          )
        ],
      ),
      subtitle: StreamBuilder<List<int>>(
        stream: descriptor.value,
        initialData: descriptor.lastValue,
        builder: (c, snapshot) => Text(snapshot.data.toString()),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            icon: Icon(
              Icons.file_download,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            onPressed: onReadPressed,
          ),
          IconButton(
            icon: Icon(
              Icons.file_upload,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            onPressed: onWritePressed,
          )
        ],
      ),
    );
  }
}

class AdapterStateTile extends StatelessWidget {
  const AdapterStateTile({Key? key, required this.state}) : super(key: key);

  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.redAccent,
      child: ListTile(
        title: Text(
          'Bluetooth adapter is ${state.toString().substring(15)}',
        ),
        trailing: Icon(
          Icons.error,
        ),
      ),
    );
  }
}
