import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._();
  factory WebSocketService() => _instance;
  WebSocketService._();

  late StompClient _stomp;
  final _tradeController = StreamController<dynamic>.broadcast();
  final _donationController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get tradeStream => _tradeController.stream;
  Stream<dynamic> get donationStream => _donationController.stream;

  void connect(String token) {
    _stomp = StompClient(
      config: StompConfig.SockJS(
        url: 'http://10.0.2.2:8080/ws-notifications',
        onConnect: _onConnect,
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
      ),
    )..activate();
  }

  void _onConnect(StompFrame frame) {
    _stomp.subscribe(
      destination: '/user/queue/trade-requests',
      callback: (f) {
        final msg = json.decode(f.body!);
        _tradeController.add(msg['request']);
      },
    );
    _stomp.subscribe(
      destination: '/user/queue/donation-requests',
      callback: (f) {
        final msg = json.decode(f.body!);
        _donationController.add(msg['request']);
      },
    );
  }

  void disconnect() {
    _stomp.deactivate();
    _tradeController.close();
    _donationController.close();
  }
}
