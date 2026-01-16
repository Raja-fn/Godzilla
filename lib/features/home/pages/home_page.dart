import 'package:ai_health/features/auth/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          actions: <Widget>[
            IconButton(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: const Column(children: [Text("Home Page")]),
      ),
    );
  }
}
