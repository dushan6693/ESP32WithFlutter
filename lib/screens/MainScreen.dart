import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  late BluetoothConnection _connection;
  bool _connected = false;
  late BluetoothDevice _connectedDevice;
  String _dataReceived = '{"nitro": "0","pos": "0","pota": "0", "ph": "0"}';
  final TextEditingController _typedText = TextEditingController();

  String _nitro = "0";
  String _pos = "0";
  String _pota = "0";
  String _ph = "0";

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
        title: const Text("BT Serial"),
        elevation: 4.0,
        shadowColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(bottom: 80.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _connected ? 'Connected' : 'Disconnected',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(30.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          FilledButton(
                            onPressed: _connected
                                ? _disconnectFromDevice
                                : _showDeviceListPopup,
                            style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    Colors.blue.shade400),
                                foregroundColor:
                                    MaterialStateProperty.all(Colors.white)),
                            child: Text(
                                _connected ? 'Disconnect' : 'Select Device'),
                          )
                        ],
                      ),
                      if (_connected)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("Device: ${_connectedDevice.name}"),
                            Text(
                              _connectedDevice.address.toString(),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black38),
                            )
                          ],
                        )
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(30.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: TextField(
                              controller: _typedText,
                              decoration: InputDecoration(
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
                            style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    Colors.blue.shade400),
                                foregroundColor:
                                    MaterialStateProperty.all(Colors.white)),
                            child: const Text("Send"),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(30.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          FilledButton(
                            onPressed: () {
                              _connected ? _sendData(data: "5") : null;
                            },
                            style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    Colors.blue.shade400),
                                foregroundColor:
                                    MaterialStateProperty.all(Colors.white)),
                            child: Text("Read Data"),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(right: 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Nitrogen: ",
                                  style: TextStyle(fontSize: 20.0),
                                ),
                                Text(
                                  "Phosphorus: ",
                                  style: TextStyle(fontSize: 20.0),
                                ),
                                Text(
                                  "Potassium: ",
                                  style: TextStyle(fontSize: 20.0),
                                ),
                                Text(
                                  "PH: ",
                                  style: TextStyle(fontSize: 20.0),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                nitro,
                                style: const TextStyle(fontSize: 20.0),
                              ),
                              Text(
                                pos,
                                style: const TextStyle(fontSize: 20.0),
                              ),
                              Text(
                                pota,
                                style: const TextStyle(fontSize: 20.0),
                              ),
                              Text(
                                ph,
                                style: const TextStyle(fontSize: 20.0),
                              )
                            ],
                          ),
                        ],
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
            _dataReceived = receivedData;
            nitro = _getJson(receivedData, "nitro");
            pos = _getJson(receivedData, "pos");
            pota = _getJson(receivedData, "pota");
            ph = _getJson(receivedData, "ph");
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

  _getJson(String data, String name) {
    try {
      Map<String, dynamic> jsonData = jsonDecode(data);
      String value = jsonData[name];
      print(value);
      return value;
    } on FormatException catch (e) {
      print("Invalid JSON string. $e");
    }
    return '-';
  }

  String get nitro => _nitro;

  set nitro(String value) {
    _nitro = value;
  }

  String get pos => _pos;

  set pos(String value) {
    _pos = value;
  }

  String get pota => _pota;

  set pota(String value) {
    _pota = value;
  }

  String get ph => _ph;

  set ph(String value) {
    _ph = value;
  }
}
