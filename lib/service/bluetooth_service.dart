import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class DigitalIdentity {
  final String name;
  final String email;
  final String phone;

  DigitalIdentity({
    required this.name,
    required this.email,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
    };
  }

  factory DigitalIdentity.fromJson(Map<String, dynamic> json) {
    return DigitalIdentity(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class BluetoothService {
  static BluetoothConnection? _connection;
  static bool _isConnected = false;
  static String _connectedDeviceName = '';

  // Callback pour recevoir des données
  static Function(DigitalIdentity)? onDataReceived;

  static bool get isConnected => _isConnected;
  static String get connectedDeviceName => _connectedDeviceName;

  // Demander les permissions Bluetooth
  static Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> permissions = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
    ].request();

    return permissions.values.every((status) => status.isGranted);
  }

  // Vérifier si Bluetooth est activé
  static Future<bool> isBluetoothEnabled() async {
    try {
      BluetoothState state = await FlutterBluetoothSerial.instance.state;
      return state == BluetoothState.STATE_ON;
    } catch (e) {
      print('Erreur vérification Bluetooth: $e');
      return false;
    }
  }

  // Activer Bluetooth
  static Future<bool> enableBluetooth() async {
    try {
      await FlutterBluetoothSerial.instance.requestEnable();
      return await isBluetoothEnabled();
    } catch (e) {
      print('Erreur activation Bluetooth: $e');
      return false;
    }
  }

  // Rendre l'appareil découvrable
  static Future<bool> makeDiscoverable() async {
    try {
      await FlutterBluetoothSerial.instance.requestDiscoverable(300);
      return true;
    } catch (e) {
      print('Erreur rendre découvrable: $e');
      return false;
    }
  }

  // Scanner les appareils disponibles
  static Future<List<BluetoothDevice>> scanDevices() async {
    try {
      List<BluetoothDevice> devices = [];

      // Appareils appairés
      List<BluetoothDevice> pairedDevices =
          await FlutterBluetoothSerial.instance.getBondedDevices();
      devices.addAll(pairedDevices);

      return devices;
    } catch (e) {
      print('Erreur scan appareils: $e');
      return [];
    }
  }

  // Se connecter à un appareil
  static Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      _isConnected = true;
      _connectedDeviceName = device.name ?? 'Appareil inconnu';

      // Écouter les données reçues
      _connection!.input!.listen(_onDataReceived).onDone(() {
        print('Connexion fermée');
        disconnect();
      });

      return true;
    } catch (e) {
      print('Erreur connexion: $e');
      _isConnected = false;
      return false;
    }
  }

  // Déconnecter
  static void disconnect() {
    try {
      _connection?.close();
      _connection = null;
      _isConnected = false;
      _connectedDeviceName = '';
    } catch (e) {
      print('Erreur déconnexion: $e');
    }
  }

  // Envoyer des données d'identité
  static Future<bool> sendIdentity(DigitalIdentity identity) async {
    if (!_isConnected || _connection == null) return false;

    try {
      String jsonData = jsonEncode({
        'type': 'digital_identity',
        'data': identity.toJson(),
      });

      _connection!.output.add(Uint8List.fromList(utf8.encode('$jsonData\n')));
      await _connection!.output.allSent;

      return true;
    } catch (e) {
      print('Erreur envoi données: $e');
      return false;
    }
  }

  // Traiter les données reçues
  static void _onDataReceived(Uint8List data) {
    try {
      String receivedString = utf8.decode(data);
      Map<String, dynamic> receivedData = jsonDecode(receivedString.trim());

      if (receivedData['type'] == 'digital_identity') {
        DigitalIdentity identity =
            DigitalIdentity.fromJson(receivedData['data']);
        onDataReceived?.call(identity);
      }
    } catch (e) {
      print('Erreur traitement données reçues: $e');
    }
  }
}
