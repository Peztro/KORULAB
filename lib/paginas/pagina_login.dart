import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../servicio_bd.dart';
import '../paginas/pagina_inicio.dart';
import '../pagina_registro.dart';
import '../widgets/animated_widgets.dart';
import '../servicios/servicio_biometrico.dart';
import '../widgets/biometric_login_widget.dart';

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
class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animationController;
  bool _showBiometric = false;
  bool _biometricAvailable = false;
  bool _hasBiometricUser = false;
  List<BiometricType> _availableBiometrics = [];
  String _biometricType = '';
  String _biometricUsername = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
    _initBiometrics();
  }

  Future<void> _initBiometrics() async {
    final available = await BiometricAuthService.isBiometricAvailable();
    final hasBiometricUser = await BiometricAuthService.hasBiometricUser();
    final biometrics = await BiometricAuthService.getAvailableBiometrics();
    final username = await BiometricAuthService.getBiometricUsername();
    
    String biometricType = '';
    if (biometrics.isNotEmpty) {
      biometricType = BiometricAuthService.getBiometricName(biometrics.first);
    }

    setState(() {
      _biometricAvailable = available;
      _hasBiometricUser = hasBiometricUser && available;
      _availableBiometrics = biometrics;
      _biometricType = biometricType;
      _biometricUsername = username ?? '';
      _showBiometric = _hasBiometricUser;
    });
  }

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
      final isValid = await DBService.validateLogin(username: username, password: password);

      if (isValid) {
        // Guardar sesión
        await DBService.saveSession(username);
        
        // Preguntar si desea habilitar login biométrico
        if (mounted && _biometricAvailable && !_hasBiometricUser) {
          _showBiometricSetupDialog(username);
        }

        if (mounted) {
          final route = MaterialPageRoute(builder: (_) => HomePage(username: username));
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

  Future<void> _loginWithBiometric() async {
    setState(() => _isLoading = true);

    try {
      final authenticated = await BiometricAuthService.authenticate(
        reason: 'Autentica con tu $_biometricType para acceder a Korulab',
      );

      if (authenticated) {
        final username = await BiometricAuthService.getBiometricUsername();
        if (username != null && mounted) {
          final route = MaterialPageRoute(builder: (_) => HomePage(username: username));
          Navigator.of(context).pushReplacement(route);
        }
      } else {
        _showSnackBar('Autenticación biométrica cancelada');
      }
    } catch (e) {
      _showSnackBar('Error en autenticación biométrica: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showBiometricSetupDialog(String username) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seguridad biométrica'),
        content: Text(
          '¿Te gustaría usar tu $_biometricType para inicios de sesión más rápidos y seguros?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ahora no'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authenticated = await BiometricAuthService.authenticate(
                reason: 'Verifica tu identidad para habilitar login biométrico',
              );
              if (authenticated) {
                await BiometricAuthService.saveBiometricPreference(true);
                await BiometricAuthService.saveBiometricUser(username);
                _initBiometrics();
                if (mounted) {
                  _showSnackBar('Login biométrico habilitado');
                }
              }
            },
            child: const Text('Habilitar'),
          ),
        ],
      ),
    );
  }

  void _switchToPasswordLogin() {
    setState(() => _showBiometric = false);
  }

  void _switchToBiometricLogin() {
    setState(() => _showBiometric = true);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToRegister() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterPage()));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: widget.addAccount
          ? AppBar(
              backgroundColor: theme.colorScheme.surface,
              title: const Text('Agregar otra cuenta'),
            )
          : null,
      body: Center(
        child: FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo con animación
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
                    ),
                    child: Image.asset(
                      'assets/images/koruicon.png',
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Título
                  Text(
                    'Bienvenido a Korulab',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Subtítulo
                  Text(
                    _showBiometric && _hasBiometricUser
                        ? 'Usa tu $_biometricType para entrar'
                        : 'Inicia sesión para continuar',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  
                  // Mostrar biometría o contraseña según estado
                  if (_showBiometric && _hasBiometricUser) ...[
                    BiometricLoginWidget(
                      username: _biometricUsername,
                      onAuthSuccess: _loginWithBiometric,
                      onAuthFail: () => _showSnackBar('Autenticación fallida'),
                    ),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: _switchToPasswordLogin,
                      icon: const Icon(Icons.lock),
                      label: const Text('Usar contraseña en su lugar'),
                    ),
                  ] else ...[
                    // Campo de usuario con animación retrasada
                    FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0.2, 0.8),
                        ),
                      ),
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(-0.1, 0), end: Offset.zero)
                            .animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: const Interval(0.2, 0.8),
                              ),
                            ),
                        child: TextField(
                          controller: _usernameController,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: 'Usuario único',
                            hintText: 'tu_usuario',
                            prefixText: '@',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Campo de contraseña con animación retrasada
                    FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0.3, 0.9),
                        ),
                      ),
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(-0.1, 0), end: Offset.zero)
                            .animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: const Interval(0.3, 0.9),
                              ),
                            ),
                        child: TextField(
                          controller: _passwordController,
                          enabled: !_isLoading,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Botón de login animado
                    FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0.4, 1.0),
                        ),
                      ),
                      child: AnimatedElevatedButton(
                        label: _isLoading ? 'Iniciando sesión...' : 'Iniciar sesión',
                        onPressed: _isLoading ? () {} : _login,
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                    
                    // Botón biométrico si está disponible
                    if (_biometricAvailable && !_hasBiometricUser) ...[
                      const SizedBox(height: 16),
                      Divider(color: theme.colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _switchToBiometricLogin,
                        icon: Icon(
                          _availableBiometrics.contains(BiometricType.face)
                              ? Icons.face
                              : Icons.fingerprint,
                        ),
                        label: Text('O usa $_biometricType'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    // Enlace de registro
                    FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0.5, 1.0),
                        ),
                      ),
                      child: Row(
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
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
