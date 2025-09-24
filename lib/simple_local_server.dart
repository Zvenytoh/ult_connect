import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class SimpleLocalServer {
  HttpServer? _server;
  final List<String> _logs = [];
  final List<Map<String, dynamic>> _connections = [];
  String _currentIP = 'localhost';
  int _currentPort = 0;
  bool _isClosed = true;
  
  Function(List<String>)? onLogUpdate;
  Function(List<Map<String, dynamic>>)? onConnectionsUpdate;
  Function(String)? onIpUpdate;

  Future<bool> startServer(int port, {String bindTo = '0.0.0.0'}) async {
    try {
      _addLog('🚀 Tentative de démarrage du serveur...');
      _addLog('📡 Adresse: $bindTo, Port: $port');
      
      // Arrêter le serveur s'il est déjà en cours d'exécution
      if (_server != null) {
        await stopServer();
      }
      
      InternetAddress address;
      
      if (bindTo == '0.0.0.0' || bindTo == 'localhost') {
        address = InternetAddress.anyIPv4;
        _currentIP = await _getLocalIP() ?? 'localhost';
      } else {
        address = InternetAddress(bindTo);
        _currentIP = bindTo;
      }
      
      _server = await HttpServer.bind(address, port);
      _currentPort = port;
      _isClosed = false;
      
      _server!.listen((HttpRequest request) {
        _handleRequest(request);
      });
      
      _addLog('✅ Serveur démarré avec succès!');
      _addLog('🌐 URL locale: http://localhost:$_currentPort');
      _addLog('🌐 URL réseau: http://$_currentIP:$_currentPort');
      _addLog('📡 En attente de connexions...');
      
      onIpUpdate?.call(_currentIP);
      
      return true;
    } catch (e) {
      _addLog('❌ Erreur lors du démarrage: $e');
      if (e is SocketException) {
        _addLog('💡 Le port $port est peut-être déjà utilisé');
      }
      return false;
    }
  }
  
  Future<String?> _getLocalIP() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && 
              !addr.address.startsWith('127.') &&
              !addr.address.startsWith('169.254.')) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      _addLog('⚠️ Impossible de récupérer l\'adresse IP: $e');
    }
    return null;
  }
  
  void _handleRequest(HttpRequest request) {
    final clientIP = request.connectionInfo!.remoteAddress.address;
    final path = request.uri.path;
    final method = request.method;
    final timestamp = DateTime.now();
    
    final connection = {
      'ip': clientIP,
      'path': path,
      'method': method,
      'timestamp': timestamp,
      'userAgent': request.headers['user-agent']?.first ?? 'Inconnu'
    };
    
    _connections.add(connection);
    onConnectionsUpdate?.call(List.from(_connections));
    
    _addLog('🔗 NOUVELLE CONNEXION: $method $path de $clientIP');
    _addLog('   📱 User-Agent: ${connection['userAgent']}');
    _addLog('   ⏰ Time: ${timestamp.toString().split('.')[0]}');
    
    final response = request.response;
    
    try {
      switch (path) {
        case '/':
          response
            ..statusCode = HttpStatus.ok
            ..write('''Server is running! 🚀

🌐 Adresse du serveur: $_currentIP
🔗 Port: $_currentPort
👥 Connexions actives: ${_connections.length}
⏰ Démarrage: ${timestamp.toString().split('.')[0]}

Pour vous connecter depuis une autre machine:
http://$_currentIP:$_currentPort''')
            ..close();
          _addLog('   📤 Réponse 200 OK envoyée pour /');
          break;
          
        case '/api/status':
          final statusData = {
            'status': 'ok',
            'server_ip': _currentIP,
            'port': _currentPort,
            'timestamp': timestamp.toIso8601String(),
            'active_connections': _connections.length,
            'client_ip': clientIP
          };
          
          response
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(statusData))
            ..close();
          _addLog('   📊 Réponse API Status envoyée');
          break;
          
        case '/api/logs':
          final recentLogs = _logs.length <= 50 
              ? _logs 
              : _logs.sublist(_logs.length - 50);
          
          response
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'logs': recentLogs, 'server_ip': _currentIP}))
            ..close();
          _addLog('   📝 Réponse logs envoyée (${recentLogs.length} logs)');
          break;
          
        case '/api/connections':
          response
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({
              'connections': _connections,
              'server_ip': _currentIP
            }))
            ..close();
          _addLog('   🔌 Réponse connexions envoyée');
          break;
          
        default:
          response
            ..statusCode = HttpStatus.notFound
            ..write('Page not found')
            ..close();
          _addLog('   ❌ Page non trouvée (404)');
      }
      
      _addLog('   ✅ Réponse envoyée avec succès à $clientIP');
      
    } catch (e) {
      _addLog('   💥 Erreur lors de l\'envoi de la réponse: $e');
    }
    
    if (_connections.length > 20) {
      _connections.removeRange(0, _connections.length - 20);
    }
  }
  
  void _addLog(String message) {
    final timestamp = DateTime.now().toString().split('.')[0];
    final logEntry = '[$timestamp] $message';
    
    _logs.add(logEntry);
    
    if (_logs.length > 100) {
      _logs.removeRange(0, _logs.length - 100);
    }
    
    if (kDebugMode) {
      print(logEntry);
    }
    
    onLogUpdate?.call(List.from(_logs));
  }
  
  Future<void> stopServer() async {
    if (_server != null) {
      _addLog('🛑 Arrêt du serveur demandé...');
      _addLog('📊 Statistiques finales: ${_connections.length} connexions traitées');
      
      await _server!.close();
      _server = null;
      _currentPort = 0;
      _isClosed = true;
      
      _connections.clear();
      onConnectionsUpdate?.call([]);
      
      _addLog('✅ Serveur arrêté avec succès');
    }
  }
  
  // Getters
  bool get isRunning => _server != null;
  int? get port => _server != null ? _server!.port : _currentPort;
  String get currentIP => _currentIP;
  List<String> get logs => List.from(_logs);
  List<Map<String, dynamic>> get connections => List.from(_connections);
  bool get isClosed => _isClosed;
  
  void clearLogs() {
    _logs.clear();
    onLogUpdate?.call([]);
  }
}