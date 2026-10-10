import 'package:flutter/material.dart';
import '../servicio_bd.dart';
import '../paginas/pagina_inicio.dart';
import '../pagina_registro.dart';

// ─────────────────────────────────────────────
// Página de inicio de sesión - permite a los usuarios autenticarse con usuario y contraseña
// ─────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.addAccount = false});

  // Cuando es true se abre desde "Agregar otra cuenta" y permite volver atrás.
  final bool addAccount;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// Estado de la página de login - gestiona la lógica de validación y autenticación
class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _login() async {
    final username = DBService.normalizeUsername(_usernameController.text);
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('Por favor completa todos los campos');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Validar credenciales en la base de datos
      final isValid = await DBService.validateLogin(
        username: username,
        password: password,
      );

      if (isValid) {
        // Guardar sesión
        await DBService.saveSession(username);

        if (mounted) {
          final route = MaterialPageRoute(
            builder: (_) => HomePage(username: username),
          );
          if (widget.addAccount) {
            Navigator.of(context).pushAndRemoveUntil(route, (_) => false);
          } else {
            Navigator.of(context).pushReplacement(route);
          }
        }
      } else {
        _showSnackBar('Usuario o contraseña incorrectos');
      }
    } catch (e) {
      _showSnackBar('Error al iniciar sesión: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegisterPage()));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: widget.addAccount
          ? AppBar(
              backgroundColor: theme.colorScheme.surface,
              title: const Text('Agregar otra cuenta'),
            )
          : null,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/koruicon.png',
                height: 100,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Text(
                'Bienvenido a Korulab',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Inicia sesión para continuar',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _usernameController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Usuario único',
                  hintText: 'tu_usuario',
                  prefixText: '@',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿No tienes cuenta? ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isLoading ? null : _goToRegister,
                    child: Text(
                      'Regístrate',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
