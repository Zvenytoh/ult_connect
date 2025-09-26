import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bluetooth_service.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  List<BluetoothDevice> devices = [];
  bool isScanning = false;
  bool isBluetoothEnabled = false;
  DigitalIdentity? myIdentity;
  DigitalIdentity? receivedIdentity;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
    _loadMyIdentity();
    
    // Configurer le callback pour recevoir des données
    BluetoothService.onDataReceived = (identity) {
      setState(() {
        receivedIdentity = identity;
      });
      _showReceivedIdentityDialog(identity);
    };
  }

  Future<void> _initBluetooth() async {
    // Demander les permissions
    bool permissionsGranted = await BluetoothService.requestPermissions();
    if (!permissionsGranted) {
      _showErrorDialog('Permissions Bluetooth refusées');
      return;
    }

    // Vérifier si Bluetooth est activé
    bool enabled = await BluetoothService.isBluetoothEnabled();
    setState(() {
      isBluetoothEnabled = enabled;
    });

    if (!enabled) {
      enabled = await BluetoothService.enableBluetooth();
      setState(() {
        isBluetoothEnabled = enabled;
      });
    }

    if (enabled) {
      _scanDevices();
    }
  }

  Future<void> _loadMyIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      myIdentity = DigitalIdentity(
        name: prefs.getString('name') ?? '',
        email: prefs.getString('email') ?? '',
        phone: prefs.getString('phone') ?? '',
      );
    });
  }

  Future<void> _scanDevices() async {
    setState(() {
      isScanning = true;
      devices.clear();
    });

    try {
      List<BluetoothDevice> foundDevices = await BluetoothService.scanDevices();
      setState(() {
        devices = foundDevices;
        isScanning = false;
      });
    } catch (e) {
      setState(() {
        isScanning = false;
      });
      _showErrorDialog('Erreur lors du scan: $e');
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    bool success = await BluetoothService.connectToDevice(device);
    if (success) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connecté à ${device.name}')),
      );
    } else {
      _showErrorDialog('Impossible de se connecter à ${device.name}');
    }
  }

  Future<void> _sendMyIdentity() async {
    if (myIdentity == null) {
      _showErrorDialog('Aucune identité à envoyer. Configurez votre profil d\'abord.');
      return;
    }

    bool success = await BluetoothService.sendIdentity(myIdentity!);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identité envoyée avec succès')),
      );
    } else {
      _showErrorDialog('Erreur lors de l\'envoi de l\'identité');
    }
  }

  Future<void> _makeDiscoverable() async {
    bool success = await BluetoothService.makeDiscoverable();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appareil maintenant découvrable pendant 5 minutes')),
      );
    } else {
      _showErrorDialog('Impossible de rendre l\'appareil découvrable');
    }
  }

  void _showReceivedIdentityDialog(DigitalIdentity identity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Identité reçue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nom: ${identity.name}'),
            Text('Email: ${identity.email}'),
            Text('Téléphone: ${identity.phone}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Échange Bluetooth'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          if (isBluetoothEnabled)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _scanDevices,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Statut Bluetooth
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          isBluetoothEnabled ? Icons.bluetooth : Icons.bluetooth_disabled,
                          color: isBluetoothEnabled ? Colors.blue : Colors.grey,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isBluetoothEnabled ? 'Bluetooth activé' : 'Bluetooth désactivé',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    if (BluetoothService.isConnected) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.link, color: Colors.green),
                          const SizedBox(width: 10),
                          Text('Connecté à: ${BluetoothService.connectedDeviceName}'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isBluetoothEnabled ? _makeDiscoverable : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Rendre découvrable'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: BluetoothService.isConnected ? _sendMyIdentity : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text('Envoyer mon identité'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Liste des appareils
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Appareils disponibles (${devices.length})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (isScanning)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: devices.isEmpty && !isScanning
                        ? const Center(
                            child: Text(
                              'Aucun appareil trouvé.\nAssurez-vous que l\'autre appareil est découvrable.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: devices.length,
                            itemBuilder: (context, index) {
                              final device = devices[index];
                              return Card(
                                child: ListTile(
                                  leading: Icon(
                                    Icons.phone_android,
                                    color: device.isBonded ? Colors.blue : Colors.grey,
                                  ),
                                  title: Text(device.name ?? 'Appareil inconnu'),
                                  subtitle: Text(device.address),
                                  trailing: device.isBonded
                                      ? const Icon(Icons.link, color: Colors.green)
                                      : null,
                                  onTap: () => _connectToDevice(device),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            
            // Identité reçue
            if (receivedIdentity != null) ...[
              const Divider(),
              const Text(
                'Dernière identité reçue:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nom: ${receivedIdentity!.name}'),
                      Text('Email: ${receivedIdentity!.email}'),
                      Text('Téléphone: ${receivedIdentity!.phone}'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    BluetoothService.disconnect();
    super.dispose();
  }
}