import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:readybill/pages/splash_screen.dart';
import 'package:readybill/services/country_code_provider.dart';
import 'package:readybill/services/global_internet_connection_handler.dart';
import 'package:readybill/services/home_bill_item_provider.dart';
import 'package:flutter/services.dart';
import 'package:readybill/services/refund_bill_item_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CountryCodeProvider()),
        ChangeNotifierProvider(create: (_) => HomeBillItemProvider()),
        ChangeNotifierProvider(create: (_) => RefundBillItemProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const InternetConnectivityHandler(
      child: SplashScreen(),
    );
  }
}
