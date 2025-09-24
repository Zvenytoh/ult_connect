import 'package:flutter/material.dart';
import 'package:ult_connect/simple_local_server.dart';

class ServerMonitorPage extends StatefulWidget {
  final SimpleLocalServer? server;
  
  const ServerMonitorPage({super.key, this.server});
  
  @override
  _ServerMonitorPageState createState() => _ServerMonitorPageState();
}

class _ServerMonitorPageState extends State<ServerMonitorPage> {
  late SimpleLocalServer _server;
  bool _isRunning = false;
  List<String> _logs = [];
  List<Map<String, dynamic>> _connections = [];
  String _serverIP = 'localhost';

  @override
  void initState() {
    super.initState();
    _initServer();
  }

  void _initServer() {
    if (widget.server != null) {
      _server = widget.server!;
    } else {
      _server = SimpleLocalServer();
    }
    
    _server.onLogUpdate = (logs) {
      if (mounted) {
        setState(() {
          _logs = logs;
          _isRunning = _server.isRunning;
        });
      }
    };
    
    _server.onConnectionsUpdate = (connections) {
      if (mounted) {
        setState(() {
          _connections = connections;
        });
      }
    };
    
    _server.onIpUpdate = (ip) {
      if (mounted) {
        setState(() {
          _serverIP = ip;
        });
      }
    };
    
    _isRunning = _server.isRunning;
    _serverIP = _server.currentIP;
    _logs = _server.logs;
    _connections = _server.connections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monitor Serveur'),
        backgroundColor: _isRunning ? Colors.green : Colors.red,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshLogs,
          ),
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: _copyServerAddress,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildControlPanel(),
          _buildNetworkInfoPanel(),
          _buildStatsPanel(),
          Expanded(child: _buildLogsPanel()),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Serveur Local',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _isRunning 
                      ? '🟢 Serveur actif'
                      : '🔴 Serveur arrêté',
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _isRunning ? _stopServer : _startServer,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRunning ? Colors.red : Colors.green,
              ),
              child: Text(_isRunning ? 'Arrêter' : 'Démarrer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkInfoPanel() {
    final currentPort = _server.port ?? 0;
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Adresse du serveur:', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text(
                      _serverIP,
                      style: TextStyle(fontFamily: 'Monospace', fontSize: 16),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.copy, size: 18),
                      onPressed: _copyServerAddress,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Port:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('$currentPort', style: TextStyle(fontFamily: 'Monospace')),
              ],
            ),
            SizedBox(height: 8),
            if (_isRunning && currentPort > 0)
              Text(
                'URL: http://$_serverIP:$currentPort',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsPanel() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Connexions', _connections.length.toString(), Icons.people),
            _buildStatItem('Logs', _logs.length.toString(), Icons.list),
            _buildStatItem('Port', _server.port?.toString() ?? '-', Icons.network_check),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildLogsPanel() {
    return Card(
      margin: EdgeInsets.all(8),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Icon(Icons.history, size: 20),
                SizedBox(width: 8),
                Text('Logs en temps réel', style: TextStyle(fontWeight: FontWeight.bold)),
                Spacer(),
                Text('${_logs.length} entrées'),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final logIndex = _logs.length - 1 - index;
                final log = _logs[logIndex];
                
                return ListTile(
                  dense: true,
                  title: Text(
                    log,
                    style: TextStyle(fontSize: 12, fontFamily: 'Monospace'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _startServer() async {
    bool success = await _server.startServer(8080, bindTo: '0.0.0.0');
    setState(() {
      _isRunning = success;
      if (success) {
        _serverIP = _server.currentIP;
      }
    });
    
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: Impossible de démarrer le serveur'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopServer() async {
    await _server.stopServer();
    setState(() {
      _isRunning = false;
    });
  }

  void _refreshLogs() {
    setState(() {
      _logs = _server.logs;
      _connections = _server.connections;
    });
  }

  void _copyServerAddress() {
    if (_isRunning && _server.port != null) {
      final address = 'http://$_serverIP:${_server.port}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adresse à copier: $address')),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}