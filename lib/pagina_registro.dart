import 'package:flutter/material.dart';
import 'widgets/auth_layout.dart';
import 'servicio_bd.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  Future<void> _register() async {
    final username = DBService.normalizeUsername(_usernameController.text);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validaciones
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('Por favor completa todos los campos');
      return;
    }

    if (!DBService.isValidUsername(username)) {
      _showSnackBar(
        'El @usuario debe tener entre 3 y 20 caracteres: letras, números, punto o guion bajo.',
      );
      return;
    }

    if (!email.contains('@')) {
      _showSnackBar('Por favor ingresa un email válido');
      return;
    }

    if (password.length < 6) {
      _showSnackBar('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Las contraseñas no coinciden');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verificar si el usuario ya existe
      final usernameExists = await DBService.usernameExists(username);
      if (usernameExists) {
        _showSnackBar('Ese @usuario ya está ocupado');
        setState(() => _isLoading = false);
        return;
      }

      final emailExists = await DBService.emailExists(email);
      if (emailExists) {
        _showSnackBar('El email ya está registrado');
        setState(() => _isLoading = false);
        return;
      }

      // Registrar usuario
      final success = await DBService.registerUser(
        username: username,
        email: email,
        password: password,
      );

      if (success) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('¡Registro exitoso! Inicia sesión')),
        );
      } else {
        _showSnackBar('Error al registrar el usuario');
      }
    } catch (e) {
      _showSnackBar(e is StateError ? e.message : 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration passwordDecoration(
      String label,
      bool obscured,
      VoidCallback toggle,
    ) {
      return InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: obscured ? 'Mostrar contraseña' : 'Ocultar contraseña',
          icon: Icon(
            obscured
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: toggle,
        ),
      );
    }

    return AuthLayout(
      showBack: true,
      title: 'Crea tu cuenta',
      subtitle: 'Únete a Korulab y empieza tu racha verde.',
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              enabled: !_isLoading,
              autofillHints: const [AutofillHints.newUsername],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Usuario',
                hintText: 'eco_explorador',
                helperText: '3 a 20 letras, números, punto o guion bajo.',
                prefixText: '@',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _emailController,
              enabled: !_isLoading,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordController,
              enabled: !_isLoading,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              decoration: passwordDecoration(
                'Contraseña',
                _obscurePassword,
                () => setState(() => _obscurePassword = !_obscurePassword),
              ).copyWith(helperText: 'Mínimo 6 caracteres.'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirmPasswordController,
              enabled: !_isLoading,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _isLoading ? null : _register(),
              decoration: passwordDecoration(
                'Confirmar contraseña',
                _obscureConfirmPassword,
                () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
            ),
            const SizedBox(height: 24),
            LoadingButton(
              label: 'Crear cuenta',
              icon: Icons.arrow_forward_rounded,
              loading: _isLoading,
              onPressed: _register,
            ),
            const SizedBox(height: 12),
            AuthSwitchLink(
              question: '¿Ya tienes cuenta?',
              action: 'Inicia sesión',
              onTap: _isLoading ? null : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
