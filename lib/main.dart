import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

const String kAppUrl = 'https://alifmeta.vercel.app';
const Color kBrandBg = Color(0xFFF4F7F5); // matches site theme-color
const Color kBrandDark = Color(0xFF1A1A1A);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: kBrandBg,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: kBrandBg,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const AlifMedApp());
}

class AlifMedApp extends StatelessWidget {
  const AlifMedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alif Med',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kBrandBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kBrandDark,
          background: kBrandBg,
        ),
        fontFamily: 'Roboto',
      ),
      home: const WebViewHome(),
    );
  }
}

class WebViewHome extends StatefulWidget {
  const WebViewHome({super.key});

  @override
  State<WebViewHome> createState() => _WebViewHomeState();
}

class _WebViewHomeState extends State<WebViewHome> {
  late final WebViewController _controller;
  double _loadProgress = 0;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _initWebView();
  }

  void _initConnectivity() {
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (mounted) {
        setState(() => _isOffline = offline);
      }
    });
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(kBrandBg)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/120.0.0.0 Mobile Safari/537.36 AlifMedApp/1.0',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _loadProgress = progress / 100);
          },
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            // Only show full error screen for main-frame failures.
            if (mounted && error.isForMainFrame != false) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
          onNavigationRequest: (request) {
            // Keep navigation inside the webview for the same site;
            // external links (mailto, tel, other domains) open natively.
            final uri = Uri.tryParse(request.url);
            if (uri != null &&
                (uri.scheme == 'mailto' ||
                    uri.scheme == 'tel' ||
                    uri.scheme == 'sms')) {
              _launchExternal(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(kAppUrl));
  }

  Future<void> _launchExternal(String url) async {
    // Placeholder for url_launcher if you add it later.
    // For now these schemes are simply ignored inside the webview.
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    return true;
  }

  Future<void> _reload() async {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    await _controller.reload();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: kBrandBg,
        body: SafeArea(
          child: Stack(
            children: [
              if (_isOffline)
                _OfflineView(onRetry: _reload)
              else if (_hasError)
                _ErrorView(onRetry: _reload)
              else
                RefreshIndicator(
                  color: kBrandDark,
                  backgroundColor: kBrandBg,
                  onRefresh: _reload,
                  child: WebViewWidget(controller: _controller),
                ),
              if (_isLoading && !_hasError && !_isOffline)
                _LoadingOverlay(progress: _loadProgress),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  final double progress;
  const _LoadingOverlay({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBrandBg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/splash_logo.png', width: 88, height: 88),
            const SizedBox(height: 28),
            SizedBox(
              width: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress : null,
                  minHeight: 3,
                  backgroundColor: kBrandDark.withOpacity(0.08),
                  color: kBrandDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _MessageView(
      icon: Icons.error_outline_rounded,
      title: 'Something went wrong',
      subtitle: "We couldn't load Alif Med. Please try again.",
      onRetry: onRetry,
    );
  }
}

class _OfflineView extends StatelessWidget {
  final VoidCallback onRetry;
  const _OfflineView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _MessageView(
      icon: Icons.wifi_off_rounded,
      title: 'No internet connection',
      subtitle: 'Check your connection and try again.',
      onRetry: onRetry,
    );
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onRetry;

  const _MessageView({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: kBrandDark.withOpacity(0.6)),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kBrandDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: kBrandDark.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandDark,
                foregroundColor: kBrandBg,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
