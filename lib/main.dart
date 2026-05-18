import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

// ==========================================
// 1. GETX STATE MANAGEMENT
// ==========================================
class PointsController extends GetxController {
  // Static User Points
  var points = 500.obs;

  bool deductPoints(int cost) {
    if (points.value >= cost) {
      points.value -= cost;
      return true;
    }
    return false;
  }
}

// ==========================================
// 2. SIRI METHOD CHANNEL BRIDGE
// ==========================================
class SiriIntentHandler {
  static const MethodChannel _channel = MethodChannel('com.example.demo/siri_intents');
  
  void init() {
    _channel.setMethodCallHandler(_handleMethod);
    
    // CRITICAL: Wait 1 second for the Flutter GetMaterialApp UI to mount completely.
    // If we send this immediately, Get.to() will fail because there is no navigation context yet.
    Future.delayed(const Duration(milliseconds: 1000), () {
      _channel.invokeMethod('flutterIsReady');
    });
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    if (call.method == 'onSiriIntent') {
      try {
        final Map<dynamic, dynamic> args = call.arguments;
        final action = args['action'] as String;
        final data = Map<String, dynamic>.from(args['data'] as Map);
        
        developer.log('Siri Intent Received: $action data: $data');
        
        if (action == 'REDEEM_VOUCHER') {
          final type = data['type'] ?? 'Amazon'; // Default to Amazon
          
          // Force Navigation regardless of where the user is
          Get.to(() => RedeemScreen(voucherType: type));
        }
      } catch (e) {
        developer.log('Error parsing Siri intent: $e');
      }
    }
  }
}

// ==========================================
// 3. MAIN APPLICATION
// ==========================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(PointsController()); // Inject Controller globally
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SiriIntentHandler _siriHandler = SiriIntentHandler();

  @override
  void initState() {
    super.initState();
    // Start listening after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _siriHandler.init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Siri Auto Redeem App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.orange,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ==========================================
// 4. HOME SCREEN
// ==========================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pointsCtrl = Get.find<PointsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards Home'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Obx(() => Center(
              child: Text(
                '⭐ ${pointsCtrl.points.value} pts',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            )),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.mic, size: 80, color: Colors.orange),
            SizedBox(height: 20),
            Text('Ready for Siri Commands!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            Text('Say: "Hey Siri, redeem Amazon voucher from Demo"', style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 12),
            Text('Or: "Hey Siri, open and redeem this from Demo"', style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. REDEEM VOUCHER SCREEN (AUTO PROCESS)
// ==========================================
class RedeemScreen extends StatefulWidget {
  final String voucherType;
  const RedeemScreen({super.key, required this.voucherType});

  @override
  State<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends State<RedeemScreen> {
  final PointsController pointsCtrl = Get.find<PointsController>();
  bool isSuccess = false;
  String message = "Processing...";
  
  // Hardcoded Static Data
  final int voucherCost = 100;
  final String voucherCode = "AMAZON100";

  @override
  void initState() {
    super.initState();
    _processRedemptionAutomatically();
  }

  void _processRedemptionAutomatically() async {
    // 1. Simulate network delay so the user can see the "Processing" UI
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // 2. Validate and Deduct Points
    if (widget.voucherType.toLowerCase() == 'amazon') {
      if (pointsCtrl.deductPoints(voucherCost)) {
        setState(() {
          isSuccess = true;
          message = "Voucher redeemed successfully and points deducted";
        });
      } else {
        setState(() {
          isSuccess = false;
          message = "Failed: Not enough points!";
        });
      }
    } else {
      setState(() {
        isSuccess = false;
        message = "Unknown voucher type.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Redeeming Voucher')),
      backgroundColor: message == "Processing..." ? Colors.white : (isSuccess ? Colors.green.shade50 : Colors.red.shade50),
      body: Center(
        child: message == "Processing..." 
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text("Redeeming automatically...", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isSuccess ? Icons.check_circle : Icons.error, 
                         size: 100, color: isSuccess ? Colors.green : Colors.red),
                    const SizedBox(height: 24),
                    Text(
                      message, 
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, 
                                       color: isSuccess ? Colors.green : Colors.red), 
                      textAlign: TextAlign.center,
                    ),
                    if (isSuccess) ...[
                      const SizedBox(height: 32),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              const Text('Voucher Code', style: TextStyle(fontSize: 16)),
                              const SizedBox(height: 8),
                              Text(voucherCode, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.black87)),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('-$voucherCost Points Deducted', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.home),
                      label: const Text('Back to Home'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () => Get.back(),
                    )
                  ],
                ),
              ),
      ),
    );
  }
}