import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'servicio_bd.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  final void Function(String displayName, String username, Uint8List? photo)?
  onProfileChanged;

  const ProfilePage({super.key, required this.username, this.onProfileChanged});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _locationController = TextEditingController();
  final _occupationController = TextEditingController();
  final _bioController = TextEditingController();
  final _learningGoalController = TextEditingController();
  final _imagePicker = ImagePicker();

  late String _activeUsername;
  Uint8List? _profilePhoto;
  Uint8List? _banner;
  DateTime? _handleChangeAvailableAt;
  bool _canChangeHandle = false;
  bool _isAdmin = false;
  String _role = DBService.roleStudent;
  String? _gender;
  bool _isLoading = true;
  bool _loadError = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _activeUsername = DBService.normalizeUsername(widget.username);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await DBService.getUserProfile(_activeUsername);
      if (!mounted) return;
      if (profile != null) {
        _usernameController.text = DBService.normalizeUsername(
          profile['username'] as String? ?? _activeUsername,
        );
        _displayNameController.text = profile['display_name'] as String? ?? '';
        _ageController.text = profile['age']?.toString() ?? '';
        _birthYearController.text = profile['birth_year']?.toString() ?? '';
        _locationController.text = profile['location'] as String? ?? '';
        _occupationController.text = profile['occupation'] as String? ?? '';
        _bioController.text = profile['bio'] as String? ?? '';
        _learningGoalController.text =
            profile['learning_goal'] as String? ?? '';
        _profilePhoto = profile['profile_photo'] as Uint8List?;
        _banner = profile['banner'] as Uint8List?;
        _gender = profile['gender'] as String?;
        _isAdmin = (profile['is_admin'] as int? ?? 0) == 1;
        _role = profile['role'] as String? ?? DBService.roleStudent;
        final lastChange = DateTime.tryParse(
          profile['handle_changed_at'] as String? ?? '',
        );
        final accountCreated = DateTime.tryParse(
          profile['created_at'] as String? ?? '',
        );
        final cooldownAnchor = lastChange ?? accountCreated;
        _handleChangeAvailableAt = cooldownAnchor?.add(
          const Duration(days: 60),
        );
        _canChangeHandle =
            _isAdmin ||
            _handleChangeAvailableAt == null ||
            !DateTime.now().isBefore(_handleChangeAvailableAt!);
      } else {
        _usernameController.text = _activeUsername;
        _canChangeHandle = true;
      }
      setState(() {
        _isLoading = false;
        _loadError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = true;
      });
    }
  }

  Future<void> _retryProfileLoad() async {
    setState(() {
      _isLoading = true;
      _loadError = false;
    });
    await _loadProfile();
  }

  Future<void> _pickPhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      final cropped = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(builder: (_) => _PhotoCropPage(image: bytes)),
      );
      if (cropped != null && mounted) {
        setState(() => _profilePhoto = cropped);
        await _saveProfile();
      }
    } catch (_) {
      _showMessage('No se pudo abrir la galería. Inténtalo de nuevo.');
    }
  }

  Future<void> _pickBanner() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      final cropped = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder: (_) => _PhotoCropPage(image: bytes, isBanner: true),
        ),
      );
      if (cropped != null && mounted) {
        setState(() => _banner = cropped);
        await _saveProfile();
      }
    } catch (_) {
      _showMessage('No se pudo abrir la galería. Inténtalo de nuevo.');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final currentUsername = _activeUsername;
    final newUsername = DBService.normalizeUsername(_usernameController.text);
    if (!DBService.isValidUsername(newUsername)) {
      _showMessage('El @usuario debe tener entre 3 y 20 caracteres válidos.');
      return;
    }
    if (newUsername != currentUsername && !_canChangeHandle) {
      _showMessage(
        'Podrás cambiar tu @usuario el ${_formatDate(_handleChangeAvailableAt!)}.',
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final saveResult = await DBService.saveUserProfile(
        username: currentUsername,
        newUsername: newUsername,
        displayName: _displayNameController.text.trim(),
        age: int.tryParse(_ageController.text),
        birthYear: int.tryParse(_birthYearController.text),
        location: _locationController.text.trim(),
        occupation: _occupationController.text.trim(),
        bio: _bioController.text.trim(),
        learningGoal: _learningGoalController.text.trim(),
        gender: _gender,
        banner: _banner,
        profilePhoto: _profilePhoto,
      );
      if (saveResult != null) {
        _showMessage(switch (saveResult) {
          'taken' => 'Ese @usuario ya está ocupado.',
          'cooldown' => 'Solo puedes cambiar tu @usuario una vez cada 60 días.',
          'admin_handle_locked' => 'El @usuario administrador está reservado.',
          'invalid' => 'El formato del @usuario no es válido.',
          _ => 'No se encontró la cuenta para guardar los cambios.',
        });
        return;
      }
      if (newUsername != currentUsername) {
        _activeUsername = newUsername;
        _usernameController.text = newUsername;
        _handleChangeAvailableAt = DateTime.now().add(const Duration(days: 60));
        _canChangeHandle = false;
      }
      widget.onProfileChanged?.call(
        _displayNameController.text.trim(),
        newUsername,
        _profilePhoto,
      );
      _showMessage('Perfil guardado.');
    } catch (_) {
      _showMessage('No se pudo guardar el perfil. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'más adelante';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateYear(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final year = int.tryParse(value);
    if (year == null || year < 1900 || year > DateTime.now().year) {
      return 'Introduce un año válido';
    }
    return null;
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _ageController.dispose();
    _birthYearController.dispose();
    _locationController.dispose();
    _occupationController.dispose();
    _bioController.dispose();
    _learningGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No se pudo cargar tu perfil.'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _retryProfileLoad,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Mi perfil', style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 6),
                        Text(
                          'Completa tus datos para personalizar tu experiencia.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Chip(
                            avatar: const Icon(Icons.badge_outlined, size: 18),
                            label: Text('Rol: ${DBService.roleLabel(_role)}'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 3,
                            child: _banner == null
                                ? Container(
                                    color: theme.colorScheme.primaryContainer,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.image_outlined,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                  )
                                : Image.memory(_banner!, fit: BoxFit.cover),
                          ),
                        ),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: _isSaving ? null : _pickBanner,
                              icon: const Icon(Icons.panorama_outlined),
                              label: Text(
                                _banner == null
                                    ? 'Añadir banner'
                                    : 'Cambiar banner',
                              ),
                            ),
                            if (_banner != null)
                              IconButton(
                                tooltip: 'Quitar banner',
                                onPressed: _isSaving
                                    ? null
                                    : () {
                                        setState(() => _banner = null);
                                        _saveProfile();
                                      },
                                icon: const Icon(Icons.delete_outline),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 54,
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                backgroundImage: _profilePhoto == null
                                    ? null
                                    : MemoryImage(_profilePhoto!),
                                child: _profilePhoto == null
                                    ? Icon(
                                        Icons.person,
                                        size: 52,
                                        color: theme
                                            .colorScheme
                                            .onPrimaryContainer,
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                children: [
                                  TextButton.icon(
                                    onPressed: _isSaving ? null : _pickPhoto,
                                    icon: const Icon(
                                      Icons.photo_library_outlined,
                                    ),
                                    label: Text(
                                      _profilePhoto == null
                                          ? 'Añadir foto'
                                          : 'Cambiar foto',
                                    ),
                                  ),
                                  if (_profilePhoto != null)
                                    IconButton(
                                      tooltip: 'Quitar foto',
                                      onPressed: _isSaving
                                          ? null
                                          : () => setState(
                                              () => _profilePhoto = null,
                                            ),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _usernameController,
                          enabled: !_isSaving && _canChangeHandle && !_isAdmin,
                          maxLength: 20,
                          validator: (value) =>
                              DBService.isValidUsername(value ?? '')
                              ? null
                              : 'Usa de 3 a 20 letras, números, puntos o guion bajo.',
                          decoration: InputDecoration(
                            labelText: 'Usuario único',
                            prefixText: '@',
                            prefixIcon: const Icon(Icons.alternate_email),
                            helperText: _isAdmin
                                ? 'Handle reservado para la cuenta administradora.'
                                : _canChangeHandle
                                ? 'Puedes cambiarlo una vez cada 60 días.'
                                : 'Podrás cambiarlo el ${_formatDate(_handleChangeAvailableAt)}.',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _textField(
                          controller: _displayNameController,
                          label: 'Nombre para mostrar',
                          icon: Icons.badge_outlined,
                          hint: _activeUsername,
                          maxLength: 60,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _textField(
                                controller: _ageController,
                                label: 'Edad',
                                icon: Icons.cake_outlined,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty)
                                    return null;
                                  final age = int.tryParse(value);
                                  if (age == null || age < 1 || age > 120) {
                                    return 'Edad no válida';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _textField(
                                controller: _birthYearController,
                                label: 'Año de nacimiento',
                                icon: Icons.calendar_today_outlined,
                                keyboardType: TextInputType.number,
                                validator: _validateYear,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _textField(
                          controller: _locationController,
                          label: 'Ciudad o país',
                          icon: Icons.location_on_outlined,
                          maxLength: 80,
                        ),
                        const SizedBox(height: 14),
                        _textField(
                          controller: _occupationController,
                          label: 'Ocupación o estudios',
                          icon: Icons.work_outline,
                          maxLength: 100,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: _gender,
                          decoration: const InputDecoration(
                            labelText: 'Sexo',
                            prefixIcon: Icon(Icons.wc_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'male',
                              child: Text('Masculino'),
                            ),
                            DropdownMenuItem(
                              value: 'female',
                              child: Text('Femenino'),
                            ),
                            DropdownMenuItem(
                              value: 'non_binary',
                              child: Text('No binario'),
                            ),
                            DropdownMenuItem(
                              value: 'unspecified',
                              child: Text('Prefiero no especificar'),
                            ),
                          ],
                          onChanged: (value) => setState(() => _gender = value),
                        ),
                        const SizedBox(height: 14),
                        _textField(
                          controller: _learningGoalController,
                          label: 'Mi objetivo de aprendizaje',
                          icon: Icons.flag_outlined,
                          maxLength: 120,
                        ),
                        const SizedBox(height: 14),
                        _textField(
                          controller: _bioController,
                          label: 'Sobre mí',
                          icon: Icons.notes_outlined,
                          hint: 'Cuéntanos un poco sobre ti',
                          maxLines: 4,
                          maxLength: 400,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _saveProfile,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _isSaving ? 'Guardando...' : 'Guardar perfil',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _PhotoCropPage extends StatefulWidget {
  final Uint8List image;
  final bool isBanner;
  const _PhotoCropPage({required this.image, this.isBanner = false});

  @override
  State<_PhotoCropPage> createState() => _PhotoCropPageState();
}

class _PhotoCropPageState extends State<_PhotoCropPage> {
  final _controller = CropController();
  bool _cropping = false;

  void _onCropped(CropResult result) {
    if (!mounted) return;
    switch (result) {
      case CropSuccess(:final croppedImage):
        Navigator.pop(context, croppedImage);
      case CropFailure():
        setState(() => _cropping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo recortar la foto.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.isBanner ? 'Elige la parte del banner' : 'Elige la parte de la foto',
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: const [],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Crop(
                image: widget.image,
                controller: _controller,
                onCropped: _onCropped,
                aspectRatio: widget.isBanner ? 3 : 1,
                withCircleUi: !widget.isBanner,
                baseColor: Colors.black,
                maskColor: Colors.black54,
                interactive: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Text(
                widget.isBanner
                    ? 'Mueve y ajusta el recuadro para elegir cómo se verá tu banner.'
                    : 'Mueve y ajusta el círculo para elegir cómo se verá tu foto.',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _cropping
                      ? null
                      : () {
                          setState(() => _cropping = true);
                          _controller.crop();
                        },
                  icon: _cropping
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(widget.isBanner ? 'Guardar banner' : 'Guardar foto'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
