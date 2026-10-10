import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'db_service.dart';
import 'models/course_models.dart';
import 'teacher_courses.dart' show decodeActivities;

class SettingsPage extends StatefulWidget {
  final String username;
  final String displayName;
  final VoidCallback onOpenProfile;
  final VoidCallback onSwitchAccount;

  const SettingsPage({
    super.key,
    required this.username,
    required this.displayName,
    required this.onOpenProfile,
    required this.onSwitchAccount,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final Future<String> _role = DBService.getUserRole(widget.username);

  void _openRoleManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoleManagementPage(adminUsername: widget.username),
      ),
    );
  }

  void _openStudents() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentProfilesPage(requesterUsername: widget.username),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: FutureBuilder<String>(
        future: _role,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final isAdmin = snapshot.data == DBService.roleAdmin;
          final canTeach = isAdmin || snapshot.data == DBService.roleTeacher;
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: const Text('Mi perfil'),
                subtitle: const Text('Edita tu información personal.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onOpenProfile,
              ),
              ListTile(
                leading: const Icon(Icons.switch_account_outlined),
                title: const Text('Cambiar de cuenta'),
                subtitle: const Text('Alterna entre tus cuentas guardadas.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onSwitchAccount,
              ),
              ListTile(
                leading: const Icon(Icons.lock_reset),
                title: const Text('Cambiar contraseña'),
                subtitle: const Text('Restablece tu contraseña de ingreso.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) =>
                      _ChangePasswordDialog(username: widget.username),
                ),
              ),
              if (isAdmin)
                ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: const Text('Administrar roles'),
                  subtitle: const Text(
                    'Asignar administradores, profesores y estudiantes.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openRoleManagement,
                ),
              if (canTeach)
                ListTile(
                  leading: const Icon(Icons.groups_outlined),
                  title: const Text('Perfiles de estudiantes'),
                  subtitle: const Text(
                    'Consultar progreso, racha y precisión.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openStudents,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final String username;
  const _ChangePasswordDialog({required this.username});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_new.text.length < 6) {
      setState(
        () => _error = 'La nueva contraseña debe tener al menos 6 caracteres.',
      );
      return;
    }
    if (_new.text != _confirm.text) {
      setState(() => _error = 'Las contraseñas nuevas no coinciden.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    bool ok;
    try {
      ok = await DBService.changeOwnPassword(
        username: widget.username,
        currentPassword: _current.text,
        newPassword: _new.text,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'No se pudo cambiar la contraseña: $e';
      });
      return;
    }
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _saving = false;
        _error = 'La contraseña actual es incorrecta.';
      });
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Contraseña actualizada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar contraseña'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña actual'),
            ),
            TextField(
              controller: _new,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nueva contraseña'),
            ),
            TextField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar nueva contraseña',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class SupportRequestPage extends StatefulWidget {
  final String username;
  final String displayName;

  const SupportRequestPage({
    super.key,
    required this.username,
    required this.displayName,
  });

  @override
  State<SupportRequestPage> createState() => _SupportRequestPageState();
}

class _SupportRequestPageState extends State<SupportRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _category = 'Petición';
  String _email = '';
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final user = await DBService.getUser(widget.username);
    if (!mounted) return;
    setState(() {
      _email = user?['email'] as String? ?? '';
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    try {
      await DBService.createSupportRequest(
        username: widget.username,
        displayName: widget.displayName,
        email: _email,
        category: _category,
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
      );
    } catch (error) {
      debugPrint('Error enviando PQRS: $error');
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo enviar la PQRS: $error'),
          duration: const Duration(seconds: 8),
        ),
      );
      return;
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Enviar PQRS'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '${widget.displayName} · @${widget.username}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Solicitud dirigida a @koruadm',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Respuesta de soporte a: $_email',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de solicitud',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Petición',
                        child: Text('Petición'),
                      ),
                      DropdownMenuItem(value: 'Queja', child: Text('Queja')),
                      DropdownMenuItem(
                        value: 'Reclamo',
                        child: Text('Reclamo'),
                      ),
                      DropdownMenuItem(
                        value: 'Sugerencia',
                        child: Text('Sugerencia'),
                      ),
                    ],
                    onChanged: _isSending
                        ? null
                        : (value) {
                            if (value != null)
                              setState(() => _category = value);
                          },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _subjectController,
                    enabled: !_isSending,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Asunto',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Escribe un asunto.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _messageController,
                    enabled: !_isSending,
                    minLines: 5,
                    maxLines: 9,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Describe tu solicitud',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 10
                        ? 'Escribe al menos 10 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isSending ? null : _submit,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(
                      _isSending ? 'Enviando...' : 'Enviar a soporte',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class SupportReviewPage extends StatefulWidget {
  final String adminUsername;

  const SupportReviewPage({super.key, required this.adminUsername});

  @override
  State<SupportReviewPage> createState() => _SupportReviewPageState();
}

class _SupportReviewPageState extends State<SupportReviewPage> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String? _error;

  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _channel = Supabase.instance.client
        .channel('support-review-${widget.adminUsername}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DBService.supportRequestTable,
          callback: (_) => _loadRequests(silent: true),
        )
        .subscribe();
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) Supabase.instance.client.removeChannel(channel);
    super.dispose();
  }

  Future<void> _loadRequests({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final requests = await DBService.getSupportRequests(widget.adminUsername);
      if (!mounted) return;
      setState(() {
        _requests = List.of(requests);
        _isLoading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      if (silent) return;
      setState(() {
        _error = 'No se pudieron cargar las PQRS de esta cuenta.';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    String? resolutionMessage;
    if (status == 'Resuelta') {
      resolutionMessage = await _askResolutionMessage();
      if (resolutionMessage == null) return;
    }
    try {
      await DBService.updateSupportRequestStatus(
        adminUsername: widget.adminUsername,
        requestId: id,
        status: status,
        resolutionMessage: resolutionMessage,
      );
      if (!mounted) return;
      setState(() {
        final index = _requests.indexWhere((item) => item['id'] == id);
        if (index >= 0) {
          _requests[index] = {..._requests[index], 'status': status};
        }
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar el estado: $error'),
          duration: const Duration(seconds: 8),
        ),
      );
      unawaited(_loadRequests(silent: true));
    }
  }

  void _showDetails(Map<String, dynamic> request) {
    final solution = (request['resolution'] as String?)?.trim();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solución dada'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cerrada el ${_formatClosedDate(request['resolved_at'])}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                solution == null || solution.isEmpty
                    ? 'No se registró la solución de esta PQRS.'
                    : solution,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<String?> _askResolutionMessage() {
    return showDialog<String>(
      context: context,
      builder: (_) => const _ResolutionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text('Revisión de PQRS'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Activas'),
              Tab(text: 'PQRS pasadas'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Actualizar',
              onPressed: _isLoading ? null : _loadRequests,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : TabBarView(
                children: [
                  _buildList(
                    theme,
                    _requests.where((r) => r['status'] != 'Resuelta').toList(),
                    false,
                  ),
                  _buildList(
                    theme,
                    _requests.where((r) => r['status'] == 'Resuelta').toList(),
                    true,
                  ),
                ],
              ),
      ),
    );
  }

  String _formatClosedDate(dynamic value) {
    final date = value is String ? DateTime.tryParse(value) : null;
    if (date == null) return 'Fecha no registrada';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  Widget _buildList(
    ThemeData theme,
    List<Map<String, dynamic>> requests,
    bool past,
  ) {
    if (requests.isEmpty) {
      return Center(
        child: Text(past ? 'Aún no hay PQRS pasadas.' : 'No hay PQRS activas.'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        final id = request['id'] as int;
        final status = request['status'] as String;
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.65),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request['subject'] as String,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text('${request['category']} · $status'),
                const SizedBox(height: 8),
                Text(
                  '${request['display_name']} · @${request['author_handle']}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(request['message'] as String),
                const SizedBox(height: 12),
                if (past)
                  Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cerrada el ${_formatClosedDate(request['resolved_at'])}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showDetails(request),
                        child: const Text('Detalles'),
                      ),
                    ],
                  )
                else
                  DropdownButtonFormField<String>(
                    key: ValueKey('support-status-$id-$status'),
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Pendiente',
                        child: Text('Pendiente'),
                      ),
                      DropdownMenuItem(
                        value: 'En revisión',
                        child: Text('En revisión'),
                      ),
                      DropdownMenuItem(
                        value: 'Resuelta',
                        child: Text('Resuelta'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null && value != status) {
                        _updateStatus(id, value);
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResolutionDialog extends StatefulWidget {
  const _ResolutionDialog();

  @override
  State<_ResolutionDialog> createState() => _ResolutionDialogState();
}

class _ResolutionDialogState extends State<_ResolutionDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _controller.text.trim().length >= 10;
    return AlertDialog(
      title: const Text('¿Cómo se resolvió?'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 4,
        maxLines: 7,
        maxLength: 1000,
        decoration: const InputDecoration(
          hintText: 'Escribe la respuesta que recibirá el usuario.',
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: canSend
              ? () => Navigator.pop(context, _controller.text.trim())
              : null,
          child: const Text('Enviar y resolver'),
        ),
      ],
    );
  }
}

class MessagesPage extends StatefulWidget {
  final String username;

  const MessagesPage({super.key, required this.username});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _canSend = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final messages = await DBService.getMessages(widget.username);
      final canSend = await DBService.canSendBroadcastMessages(widget.username);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _canSend = canSend;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los mensajes: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _composeBroadcast() async {
    final sent = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BroadcastMessagePage(senderUsername: widget.username),
      ),
    );
    if (!mounted || sent != true) return;
    await _loadMessages();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mensaje enviado a todos los usuarios.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Mensajes'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          if (_canSend)
            IconButton(
              tooltip: 'Enviar mensaje a todos',
              onPressed: _composeBroadcast,
              icon: const Icon(Icons.campaign_outlined),
            ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _isLoading ? null : _loadMessages,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loadMessages,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : _messages.isEmpty
          ? const Center(child: Text('Todavía no tienes mensajes.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _messages[index];
                final kind = item['kind'] as String? ?? 'general';
                final requestId = item['support_request_id'];
                final createdAt = DateTime.tryParse(
                  item['created_at'] as String? ?? '',
                );
                return Card(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.65,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              kind == 'general'
                                  ? Icons.campaign_outlined
                                  : Icons.support_agent,
                              color: theme.colorScheme.primaryContainer,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item['title'] as String,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(item['message'] as String),
                        const SizedBox(height: 10),
                        Text(
                          [
                            '@${item['sender_username']}',
                            if (requestId != null) 'PQRS #$requestId',
                            if (createdAt != null)
                              MaterialLocalizations.of(
                                context,
                              ).formatMediumDate(createdAt),
                          ].join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class BroadcastMessagePage extends StatefulWidget {
  final String senderUsername;

  const BroadcastMessagePage({super.key, required this.senderUsername});

  @override
  State<BroadcastMessagePage> createState() => _BroadcastMessagePageState();
}

class _BroadcastMessagePageState extends State<BroadcastMessagePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    try {
      await DBService.sendBroadcastMessage(
        senderUsername: widget.senderUsername,
        title: _titleController.text,
        message: _messageController.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo enviar el mensaje: $error'),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Mensaje para todos'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Este comunicado aparecerá en la bandeja de mensajes de todos los usuarios.',
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              enabled: !_isSending,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Asunto',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Escribe un asunto.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageController,
              enabled: !_isSending,
              minLines: 5,
              maxLines: 10,
              maxLength: 3000,
              decoration: const InputDecoration(
                labelText: 'Mensaje',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Escribe el mensaje.'
                  : null,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isSending ? null : _send,
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(_isSending ? 'Enviando...' : 'Enviar a todos'),
            ),
          ],
        ),
      ),
    );
  }
}

class RoleManagementPage extends StatefulWidget {
  final String adminUsername;

  const RoleManagementPage({super.key, required this.adminUsername});

  @override
  State<RoleManagementPage> createState() => _RoleManagementPageState();
}

class _RoleManagementPageState extends State<RoleManagementPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _updatingUsers = {};
  final Set<String> _deletingUsers = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await DBService.getUsersForRoleManagement(
        widget.adminUsername,
      );
      if (!mounted) return;
      setState(() {
        _users = List.of(users);
        _isLoading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'No se pudieron cargar las cuentas.';
      });
    }
  }

  Future<void> _changeRole(String username, String role) async {
    setState(() => _updatingUsers.add(username));
    try {
      final updated = await DBService.updateUserRole(
        adminUsername: widget.adminUsername,
        targetUsername: username,
        role: role,
      );
      if (!mounted) return;
      if (!updated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cambiar el rol de la cuenta.'),
          ),
        );
        return;
      }
      setState(() {
        final index = _users.indexWhere((item) => item['username'] == username);
        if (index >= 0) {
          _users[index] = {
            ..._users[index],
            'role': role,
            'is_admin': role == DBService.roleAdmin ? 1 : 0,
          };
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al guardar el rol.')));
    } finally {
      if (mounted) setState(() => _updatingUsers.remove(username));
    }
  }

  Future<void> _deleteTeacherAccount(
    String username,
    String? displayName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar cuenta de profesor?'),
        content: Text(
          'Se eliminará ${displayName?.isNotEmpty == true ? displayName : '@$username'} '
          'junto con sus unidades, contenidos de Korucol y datos asociados. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar cuenta'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingUsers.add(username));
    try {
      await DBService.deleteManagedAccount(
        adminUsername: widget.adminUsername,
        targetUsername: username,
      );
      if (!mounted) return;
      setState(() {
        _users.removeWhere((user) => user['username'] == username);
        _deletingUsers.remove(username);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La cuenta @$username fue eliminada.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _deletingUsers.remove(username));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar la cuenta: $error')),
      );
      await _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Cuentas y roles'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'ADMINISTRADORES',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Gestionan cuentas, PQRS y todo el contenido.'),
                const SizedBox(height: 16),
                Text(
                  'PROFESORES',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pueden moderar cualquier publicación o comentario de Korublog.',
                ),
                const SizedBox(height: 16),
                Text(
                  'ESTUDIANTES',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Participan y gestionan sus propias publicaciones y comentarios.',
                ),
                const SizedBox(height: 24),
                Text(
                  'Cuentas',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ..._users.map((user) {
                  final username = user['username'] as String;
                  final role = user['role'] as String? ?? DBService.roleStudent;
                  final displayName = (user['display_name'] as String?)?.trim();
                  final isSystemAdmin =
                      username == DBService.adminUsername ||
                      username == DBService.koruColUsername;
                  final isCurrentAdmin =
                      username ==
                      DBService.normalizeUsername(widget.adminUsername);
                  final canDeleteTeacher =
                      role == DBService.roleTeacher &&
                      !isSystemAdmin &&
                      !isCurrentAdmin;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      displayName == null || displayName.isEmpty
                          ? '@$username'
                          : displayName,
                    ),
                    subtitle: Text('@$username'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSystemAdmin || isCurrentAdmin)
                          Text(DBService.roleLabel(role))
                        else
                          DropdownButton<String>(
                            value: role,
                            onChanged:
                                _updatingUsers.contains(username) ||
                                    _deletingUsers.contains(username)
                                ? null
                                : (value) {
                                    if (value != null && value != role) {
                                      _changeRole(username, value);
                                    }
                                  },
                            items: const [
                              DropdownMenuItem(
                                value: DBService.roleAdmin,
                                child: Text('Administrador'),
                              ),
                              DropdownMenuItem(
                                value: DBService.roleTeacher,
                                child: Text('Profesor'),
                              ),
                              DropdownMenuItem(
                                value: DBService.roleStudent,
                                child: Text('Estudiante'),
                              ),
                            ],
                          ),
                        if (canDeleteTeacher)
                          IconButton(
                            tooltip: 'Eliminar cuenta de profesor',
                            onPressed: _deletingUsers.contains(username)
                                ? null
                                : () => _deleteTeacherAccount(
                                    username,
                                    displayName,
                                  ),
                            icon: _deletingUsers.contains(username)
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    Icons.delete_outline,
                                    color: theme.colorScheme.error,
                                  ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class CreateTeacherLessonPage extends StatefulWidget {
  final String teacherUsername;
  final Map<String, dynamic>? lesson;
  final String initialDestination;

  const CreateTeacherLessonPage({
    super.key,
    required this.teacherUsername,
    this.lesson,
    this.initialDestination = DBService.lessonDestinationKoruclases,
  });

  @override
  State<CreateTeacherLessonPage> createState() =>
      _CreateTeacherLessonPageState();
}

class _CreateTeacherLessonPageState extends State<CreateTeacherLessonPage> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(
    text: widget.lesson?['title'] as String?,
  );
  late final _summaryController = TextEditingController(
    text: widget.lesson?['summary'] as String?,
  );
  late final _contentController = TextEditingController(
    text: widget.lesson?['content'] as String?,
  );
  late String _destination =
      widget.lesson?['destination'] as String? ?? widget.initialDestination;
  bool _isSaving = false;

  bool get _isEditing => widget.lesson != null;

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        final updated = await DBService.updateTeacherLesson(
          requesterUsername: widget.teacherUsername,
          lessonId: widget.lesson!['id'] as int,
          title: _titleController.text,
          summary: _summaryController.text,
          content: _contentController.text,
          destination: _destination,
        );
        if (!updated) throw StateError('Sin permiso');
      } else {
        await DBService.createTeacherLesson(
          teacherUsername: widget.teacherUsername,
          title: _titleController.text.trim(),
          summary: _summaryController.text.trim(),
          content: _contentController.text.trim(),
          destination: _destination,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar la lección.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar lección' : 'Crear lección'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('¿Dónde se publicará?', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: DBService.lessonDestinationKoruclases,
                  label: Text('Ruta Eko'),
                  icon: Icon(Icons.school_outlined),
                ),
                ButtonSegment(
                  value: DBService.lessonDestinationKorucol,
                  label: Text('Nota en Korucol'),
                  icon: Icon(Icons.sticky_note_2_outlined),
                ),
              ],
              selected: {_destination},
              onSelectionChanged: _isSaving
                  ? null
                  : (value) => setState(() => _destination = value.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              enabled: !_isSaving,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Escribe un título.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _summaryController,
              enabled: !_isSaving,
              maxLength: 180,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Resumen',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Escribe un resumen.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              enabled: !_isSaving,
              minLines: 8,
              maxLines: 16,
              maxLength: 6000,
              decoration: const InputDecoration(
                labelText: 'Contenido de la lección',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().length < 20
                  ? 'Escribe al menos 20 caracteres.'
                  : null,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveLesson,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.publish_outlined),
              label: Text(
                _isSaving
                    ? 'Guardando...'
                    : _isEditing
                    ? 'Guardar cambios'
                    : 'Publicar lección',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentProfilesPage extends StatefulWidget {
  final String requesterUsername;

  const StudentProfilesPage({super.key, required this.requesterUsername});

  @override
  State<StudentProfilesPage> createState() => _StudentProfilesPageState();
}

class _StudentProfilesPageState extends State<StudentProfilesPage> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _error;
  final Set<String> _deletingStudents = {};

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final isAdmin = await DBService.isAdmin(widget.requesterUsername);
      final students = await DBService.getStudentLearningProfiles(
        widget.requesterUsername,
      );
      if (!mounted) return;
      setState(() {
        _students = students;
        _isAdmin = isAdmin;
        _isLoading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los perfiles.';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteStudent(String username, String? displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar cuenta de estudiante?'),
        content: Text(
          'Se eliminará ${displayName?.isNotEmpty == true ? displayName : '@$username'} '
          'y sus datos asociados. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar cuenta'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingStudents.add(username));
    try {
      await DBService.deleteManagedAccount(
        adminUsername: widget.requesterUsername,
        targetUsername: username,
      );
      if (!mounted) return;
      setState(() {
        _students.removeWhere((student) => student['username'] == username);
        _deletingStudents.remove(username);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La cuenta @$username fue eliminada.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _deletingStudents.remove(username));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar la cuenta: $error')),
      );
      await _loadStudents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _isAdmin
              ? 'Gestión de perfiles de estudiantes'
              : 'Perfiles de estudiantes',
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _isLoading ? null : _loadStudents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _students.isEmpty
          ? const Center(child: Text('Todavía no hay estudiantes registrados.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final name = (student['display_name'] as String?)?.trim();
                final username = student['username'] as String;
                final photo = student['profile_photo'] as Uint8List?;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.55,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: photo == null
                          ? null
                          : MemoryImage(photo),
                      child: photo == null
                          ? const Icon(Icons.person_outline)
                          : null,
                    ),
                    title: Text(
                      name == null || name.isEmpty ? '@$username' : name,
                    ),
                    subtitle: Text(
                      '${student['completed_lessons']} lecciones · Racha ${student['daily_streak']} · Precisión ${student['accuracy_percent']}%',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isAdmin)
                          IconButton(
                            tooltip: 'Eliminar cuenta de estudiante',
                            onPressed: _deletingStudents.contains(username)
                                ? null
                                : () => _deleteStudent(username, name),
                            icon: _deletingStudents.contains(username)
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    Icons.delete_outline,
                                    color: theme.colorScheme.error,
                                  ),
                          ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentProfileDetailsPage(
                          student: student,
                          requesterUsername: widget.requesterUsername,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class StudentProfileDetailsPage extends StatefulWidget {
  final Map<String, dynamic> student;
  final String requesterUsername;

  const StudentProfileDetailsPage({
    super.key,
    required this.student,
    required this.requesterUsername,
  });

  @override
  State<StudentProfileDetailsPage> createState() =>
      _StudentProfileDetailsPageState();
}

class _StudentProfileDetailsPageState extends State<StudentProfileDetailsPage> {
  late final Future<Map<String, List<Map<String, dynamic>>>> _activity =
      DBService.getStudentCommunityActivity(
        widget.requesterUsername,
        widget.student['username'] as String,
      );
  late final Future<List<String>> _lessons = _loadLessonTitles();

  Future<List<String>> _loadLessonTitles() async {
    final ids =
        (widget.student['completed_ids'] as List?)?.cast<String>() ?? [];
    final teacherLessons = await DBService.getTeacherLessons();
    final teacherTitles = {
      for (final l in teacherLessons)
        'teacher:${l['id']}': l['title'] as String,
    };
    for (final course in await DBService.getTeacherCourses()) {
      final activities = decodeActivities(course['activities'] as String?);
      for (var i = 0; i < activities.length; i++) {
        teacherTitles['custom:${course['id']}:$i'] =
            '${course['title']} · ${activities[i]['title']}';
      }
    }
    return [for (final id in ids) teacherTitles[id] ?? describeActivityId(id)];
  }

  Future<void> _resetPassword() async {
    final username = widget.student['username'] as String;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restablecer contraseña'),
        content: Text(
          'Se generará una contraseña temporal para @$username y la '
          'contraseña actual dejará de funcionar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      final temp = await DBService.resetStudentPassword(
        widget.requesterUsername,
        username,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Contraseña temporal'),
          content: SelectableText(
            'Entrega esta contraseña a @$username:\n\n$temp',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo restablecer: $e')));
    }
  }

  Widget _section(ThemeData theme, String title) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 8),
    child: Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final theme = Theme.of(context);
    final photo = student['profile_photo'] as Uint8List?;
    final displayName = (student['display_name'] as String?)?.trim();
    final username = student['username'] as String;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Perfil del estudiante'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: photo == null ? null : MemoryImage(photo),
              child: photo == null ? const Icon(Icons.person, size: 44) : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              displayName == null || displayName.isEmpty
                  ? '@$username'
                  : displayName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(child: Text('@$username')),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 20,
            runSpacing: 16,
            children: [
              _StudentMetric(
                value: '${student['completed_lessons']}',
                label: 'Lecciones',
              ),
              _StudentMetric(
                value: '${student['daily_streak']}',
                label: 'Racha',
              ),
              _StudentMetric(
                value: '${student['accuracy_percent']}%',
                label: 'Precisión',
              ),
            ],
          ),
          const Divider(height: 32),
          if (student['age'] != null)
            _StudentDetail(label: 'Edad', value: '${student['age']}'),
          if (student['birth_year'] != null)
            _StudentDetail(
              label: 'Año de nacimiento',
              value: '${student['birth_year']}',
            ),
          if ((student['location'] as String? ?? '').isNotEmpty)
            _StudentDetail(
              label: 'Ubicación',
              value: student['location'] as String,
            ),
          if ((student['occupation'] as String? ?? '').isNotEmpty)
            _StudentDetail(
              label: 'Ocupación o estudios',
              value: student['occupation'] as String,
            ),
          if ((student['learning_goal'] as String? ?? '').isNotEmpty)
            _StudentDetail(
              label: 'Objetivo de aprendizaje',
              value: student['learning_goal'] as String,
            ),
          if ((student['bio'] as String? ?? '').isNotEmpty)
            _StudentDetail(
              label: 'Sobre el estudiante',
              value: student['bio'] as String,
            ),
          const Divider(height: 32),
          OutlinedButton.icon(
            onPressed: _resetPassword,
            icon: const Icon(Icons.lock_reset),
            label: const Text('Restablecer contraseña'),
          ),
          const Divider(height: 32),
          _section(theme, 'Lecciones completadas'),
          FutureBuilder<List<String>>(
            future: _lessons,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.isEmpty) {
                return const Text('Aún no ha completado lecciones.');
              }
              return Column(
                children: [
                  for (final title in snapshot.data!)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(title),
                    ),
                ],
              );
            },
          ),
          FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
            future: _activity,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('No se pudo cargar su actividad.');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final posts = snapshot.data!['posts']!;
              final replies = snapshot.data!['replies']!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section(theme, 'Publicaciones'),
                  if (posts.isEmpty) const Text('Sin publicaciones.'),
                  for (final post in posts)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.forum_outlined),
                      title: Text(post['title'] as String),
                      subtitle: Text(
                        post['description'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  _section(theme, 'Comentarios'),
                  if (replies.isEmpty) const Text('Sin comentarios.'),
                  for (final reply in replies)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: Text(reply['message'] as String),
                      subtitle: Text(
                        'En: ${reply['discussion_title'] ?? 'publicación eliminada'}',
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StudentMetric extends StatelessWidget {
  final String value;
  final String label;

  const _StudentMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primaryContainer,
          ),
        ),
        Text(label),
      ],
    );
  }
}

class _StudentDetail extends StatelessWidget {
  final String label;
  final String value;

  const _StudentDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
