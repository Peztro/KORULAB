import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../servicio_bd.dart';
import '../paginas/pagina_inicio.dart';
import '../pagina_registro.dart';
import 'pagina_recuperar_contrasena.dart';
import '../widgets/auth_layout.dart';
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
class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
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
    final biometrics = await BiometricAuthService.getAvailableBiometrics();

    String biometricType = '';
    if (biometrics.isNotEmpty) {
      biometricType = BiometricAuthService.nombreAmigable(biometrics);
    }

    setState(() {
      _biometricAvailable = available;
      _availableBiometrics = biometrics;
      _biometricType = biometricType;
      _showBiometric = false; // Por defecto no mostrar biometría
    });

    // Buscar última cuenta usada para auto-completar campos
    await _autoLoadLastAccount();
  }

  Future<void> _autoLoadLastAccount() async {
    final lastUsed = await DBService.getLastUsedAccount();
    if (lastUsed != null && mounted) {
      final username = lastUsed['username'] ?? '';
      final biometricEnabledForUser =
          await BiometricAuthService.isBiometricEnabled(username);

      setState(() {
        _usernameController.text = username;
        _biometricUsername = username;
        _hasBiometricUser = biometricEnabledForUser && _biometricAvailable;
        _showBiometric =
            _hasBiometricUser; // Mostrar si está habilitada PARA ESTE USUARIO
      });
    }
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
      final isValid = await DBService.validateLogin(
        username: username,
        password: password,
      );

      if (isValid) {
        // Guardar sesión
        await DBService.saveSession(username);

        // Preguntar si desea habilitar login biométrico
        if (mounted && _biometricAvailable && !_hasBiometricUser) {
          _showBiometricSetupDialog(username);
        }

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

  /// Tras verificar la huella, entra con la sesión guardada de esa cuenta.
  /// Si no hay sesión guardada (por ejemplo, tras cerrar sesión), hace falta
  /// la contraseña una vez.
  Future<void> _loginWithBiometric() async {
    setState(() => _isLoading = true);
    try {
      final handle = DBService.normalizeUsername(_biometricUsername);
      final accounts = await DBService.getSavedAccounts();
      final account = accounts
          .where((a) => DBService.normalizeUsername(a.username) == handle)
          .firstOrNull;
      if (account == null) {
        _showSnackBar('Para usar la huella, entra una vez con tu contraseña.');
        _switchToPasswordLogin();
        return;
      }
      final username = await DBService.switchAccount(account.id);
      if (!mounted) return;
      final route = MaterialPageRoute(
        builder: (_) => HomePage(username: username),
      );
      if (widget.addAccount) {
        Navigator.of(context).pushAndRemoveUntil(route, (_) => false);
      } else {
        Navigator.of(context).pushReplacement(route);
      }
    } catch (e) {
      _showSnackBar(
        e is StateError ? e.message : 'No se pudo entrar con la huella.',
      );
      _switchToPasswordLogin();
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                await BiometricAuthService.saveBiometricPreference(
                  true,
                  username,
                );
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
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fade = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    final useBiometric = _showBiometric && _hasBiometricUser;

    return FadeTransition(
      opacity: fade,
      child: AuthLayout(
        showBack: widget.addAccount,
        title: widget.addAccount ? 'Agregar otra cuenta' : 'Hola de nuevo',
        subtitle: useBiometric
            ? 'Usa tu $_biometricType para entrar.'
            : 'Inicia sesión para seguir aprendiendo.',
        child: useBiometric
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BiometricLoginWidget(
                    username: _biometricUsername,
                    onAuthSuccess: _loginWithBiometric,
                    onAuthFail: () => _showSnackBar('Autenticación fallida'),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _switchToPasswordLogin,
                    icon: const Icon(Icons.password_rounded),
                    label: const Text('Usar contraseña'),
                  ),
                ],
              )
            : AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _usernameController,
                      enabled: !_isLoading,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        hintText: 'tu_usuario',
                        prefixText: '@',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      enabled: !_isLoading,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _isLoading ? null : _login(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RecuperarContrasenaPage(
                                    usuarioInicial: _usernameController.text,
                                  ),
                                ),
                              ),
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    LoadingButton(
                      label: 'Iniciar sesión',
                      icon: Icons.arrow_forward_rounded,
                      loading: _isLoading,
                      onPressed: _login,
                    ),
                    if (_biometricAvailable && !_hasBiometricUser) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'o',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _switchToBiometricLogin,
                        icon: Icon(
                          _availableBiometrics.contains(BiometricType.face)
                              ? Icons.face_rounded
                              : Icons.fingerprint_rounded,
                        ),
                        label: Text('Entrar con $_biometricType'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    AuthSwitchLink(
                      question: '¿No tienes cuenta?',
                      action: 'Regístrate',
                      onTap: _isLoading ? null : _goToRegister,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
