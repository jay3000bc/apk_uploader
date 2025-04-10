import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:readybill/components/color_constants.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class InternetConnectivityHandler extends StatefulWidget {
  final Widget child;

  const InternetConnectivityHandler({
    super.key,
    required this.child,
  });

  @override
  State<InternetConnectivityHandler> createState() =>
      _InternetConnectivityHandlerState();
}

class _InternetConnectivityHandlerState
    extends State<InternetConnectivityHandler> with WidgetsBindingObserver {
  late InternetConnection _internetConnection;
  StreamSubscription? _connectivitySubscription;
  bool _isNoInternetScreenShowing = false;
  Timer? _noInternetTimer;
  bool _isInForeground = true;

  @override
  void initState() {
    super.initState();
    _internetConnection = InternetConnection();
    WidgetsBinding.instance.addObserver(this);
    _initializeConnectivityListener();
  }

  @override
  void dispose() {
    _cleanupConnectivity();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _cleanupConnectivity() {
    _connectivitySubscription?.cancel();
    _noInternetTimer?.cancel();
    _connectivitySubscription = null;
    _noInternetTimer = null;
  }

  Future<void> _initializeConnectivityListener() async {
    try {
      _cleanupConnectivity();

      // Only start monitoring if the app is in foreground
      if (!_isInForeground) {
        return;
      }

      // Initial check
      bool hasInternet = await _internetConnection.hasInternetAccess;
      if (mounted) {
        _handleConnectivityChange(hasInternet);
      }

      // Start listening to changes
      _connectivitySubscription = _internetConnection.onStatusChange.listen(
        (InternetStatus status) {
          if (mounted && _isInForeground) {
            _handleConnectivityChange(status == InternetStatus.connected);
          }
        },
        onError: (error) {
          debugPrint('Connectivity error: $error');
        },
      );
    } catch (e) {
      debugPrint('Error initializing connectivity listener: $e');
    }
  }

  void _handleConnectivityChange(bool hasInternet) {
    if (!_isInForeground) return; // Don't handle changes when in background

    // Cancel any existing timer
    _noInternetTimer?.cancel();

    if (!hasInternet && !_isNoInternetScreenShowing) {
      // Start a new timer when internet is lost
      _noInternetTimer = Timer(const Duration(seconds: 3), () {
        if (!hasInternet &&
            mounted &&
            !_isNoInternetScreenShowing &&
            _isInForeground) {
          _isNoInternetScreenShowing = true;
          navigatorKey.currentState?.push(
            CupertinoPageRoute(builder: (_) => const NoInternetScreen()),
          );
        }
      });
    } else if (hasInternet && _isNoInternetScreenShowing) {
      _noInternetTimer?.cancel();
      _isNoInternetScreenShowing = false;
      navigatorKey.currentState?.pop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isInForeground = true;
        _initializeConnectivityListener();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _isInForeground = false;
        _cleanupConnectivity();
        // Clear the "No Internet" screen if it's showing when going to background
        if (_isNoInternetScreenShowing) {
          _isNoInternetScreenShowing = false;
          navigatorKey.currentState?.pop();
        }
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //  showPerformanceOverlay: true,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: green2,
          brightness: Brightness.light,
          primary: green2,
        ),
      ),
      navigatorKey: navigatorKey,
      home: widget.child,
      debugShowCheckedModeBanner: false,
      builder: EasyLoading.init(),
    );
  }
}

class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 80,
                    color: red,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Internet Connection',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: red,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please check your internet connection and try again.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: red,
                        ),
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(red),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
