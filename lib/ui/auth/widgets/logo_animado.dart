import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LogoAnimado extends StatefulWidget {
  const LogoAnimado({Key? key}) : super(key: key);

  @override
  State<LogoAnimado> createState() => _LogoAnimadoState();
}

class _LogoAnimadoState extends State<LogoAnimado>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_animation.value), // movimiento vertical
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 130,
                width: 130,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/img/logo.png'),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                'Sabores de mi tierra',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
