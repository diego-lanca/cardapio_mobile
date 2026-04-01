import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Rotisseria do Mércio',
                style: TextStyle(
                  fontFamily: 'Inter Fallback',
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  color: Color(0xFF09090B)
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Faça Login, para realizar seu pedido',
                style: TextStyle(
                  fontFamily: 'Inter Fallback',
                  fontWeight: FontWeight.normal,
                  fontSize: 18,
                  color: Color(0xFF09090B)
                ),
              ),
              SizedBox(height: 26),

              TextField(
                controller: null,
                style: TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  labelStyle: TextStyle(
                    color: Color(0xFF09090B)
                  ),
                  hintText: 'exemplo@gmail.com',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Color(0xFF0EA5E9),

                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Color(0xFF0EA5E9),
                      width: 2.5,
                    ),
                  ),

                ),
              ),
              SizedBox(height: 16),

              TextField(
                controller: null,
                style: TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: Icon(Icons.lock_outline),
                  labelStyle: TextStyle(
                    color: Color(0xFF09090B)
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Color(0xFF0EA5E9),
                    )
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Color(0xFF0EA5E9),
                      width: 2.5
                    )
                  )
                ),
                obscureText: true,
              )
            ],
          ),
        ),
      ),
    );
  }
}