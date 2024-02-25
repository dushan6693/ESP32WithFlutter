import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  late BluetoothConnection _connection;
  bool _connected = false;
  late BluetoothDevice _connectedDevice;
  String _dataToSend = "";
  String _dataReceived = "";
  List<BluetoothDevice> _devicesList = [];
  bool _searching = false;
  TextEditingController _typedText = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isBluetoothEnabled();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade400,
        foregroundColor: Colors.white,
        title: Text("BT Serial"),
        elevation: 4.0,
        shadowColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(bottom: 80.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _connected ? 'Connected' : 'Disconnected',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(30.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          FilledButton(
                            onPressed: _connected
                                ? _disconnectFromDevice
                                : _showDeviceListPopup,
                            child: Text(
                                _connected ? 'Disconnect' : 'Select Device'),
                            style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    Colors.blue.shade400),
                                foregroundColor:
                                    MaterialStateProperty.all(Colors.white)),
                          )
                        ],
                      ),
                      if (_connected)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("Device: " + _connectedDevice.name.toString()),
                            Text(
                              _connectedDevice.address.toString(),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black38),
                            )
                          ],
                        )
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(30.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: TextField(
                              controller: _typedText,
                              decoration: new InputDecoration(
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(
                                      color: Colors.blue.shade400, width: 2.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(
                                      color: Colors.blue.shade200, width: 2.0),
                                ),
                                hintText: 'Enter Data to send',
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          FilledButton(
                            onPressed: () {
                              _connected
                                  ? _sendData(data: _typedText.text)
                                  : null;
                            },
                            child: Text("Send"),
                            style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    Colors.blue.shade400),
                                foregroundColor:
                                    MaterialStateProperty.all(Colors.white)),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(30.0),
                  child: Row(
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Container(
                            padding: EdgeInsets.only(top: 5.0, left: 5.0),
                            child: Text(
                              "$_dataReceived\n",
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  Future<void> _isBluetoothEnabled() async {
    super.initState();
    bool? isAvailable = await _bluetooth.isAvailable;

    if (isAvailable ?? false) {
      // Check if Bluetooth is turned on
      bool? isEnabled = await _bluetooth.isEnabled;

      if (!isEnabled! ?? false) {
        // Request to turn on Bluetooth
        await _bluetooth.requestEnable();
      }
    } else {
      print('Bluetooth is not available on this device.');
    }
  }

  Future<void> _showDeviceListPopup() async {
    _bluetooth.cancelDiscovery(); // Cancel any ongoing discovery

    List<BluetoothDevice> devices = [];

    try {
      devices = await _bluetooth.getBondedDevices();
    } catch (ex) {
      print("Error getting bonded devices: $ex");
    }

    if (devices.isEmpty) {
      print("No bonded devices available");
      return;
    }

    BluetoothDevice selectedDevice = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select a device'),
          content: Column(
            children: <Widget>[
              for (BluetoothDevice device in devices)
                ListTile(
                  title: Text(device.name.toString()),
                  subtitle: Text(device.address),
                  onTap: () {
                    Navigator.pop(context, device);
                  },
                ),
            ],
          ),
        );
      },
    );

    if (selectedDevice != null) {
      await _connectToDevice(selectedDevice);
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(device.address);
      print("Connected to ${device.name}");

      // Start listening for incoming data
      connection.input?.listen(
        (Uint8List data) {
          String receivedData = utf8.decode(data);
          print("Received data: $receivedData");
          setState(() {
            _dataReceived = _dataReceived + receivedData;
          });
        },
        onDone: () {
          print("Disconnected remotely!");
          _disconnectFromDevice();
        },
        onError: (error) {
          print("Error receiving data: $error");
        },
      );

      setState(() {
        _connected = true;
        _connection = connection;
        _connectedDevice = device;
      });
    } catch (ex) {
      print("Error connecting to device: $ex");
    }
  }

  void _disconnectFromDevice() {
    if (_connection != null) {
      _connection.finish();
      setState(() {
        _connected = false;
      });
    }
  }

  void _sendData({required String data}) {
    if (_connection != null) {
      data = "$data\n";
      _connection.output.add(Uint8List.fromList(data.codeUnits));
      _connection.output.allSent.then((_) {
        print("Data sent successfully");
      });
    }
  }
}
