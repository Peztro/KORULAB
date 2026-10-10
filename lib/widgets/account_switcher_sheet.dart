import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../db_service.dart';

class AccountSwitcherSheet extends StatefulWidget {
  const AccountSwitcherSheet({required this.onSwitch, required this.onAdd});

  final void Function(Map<String, dynamic> account) onSwitch;
  final VoidCallback onAdd;

  @override
  State<AccountSwitcherSheet> createState() => AccountSwitcherSheetState();
}

class AccountSwitcherSheetState extends State<AccountSwitcherSheet> {
  List<Map<String, dynamic>> _accounts = [];
  final Set<String> _forgettingAccounts = {};
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _reloadAccounts();
  }

  Future<void> _reloadAccounts() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final accounts = await DBService.getSavedAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'No se pudieron cargar las cuentas: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _forget(Map<String, dynamic> account) async {
    final username = account['username'] as String? ?? '';
    final shouldForget = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Estás seguro?'),
        content: Text(
          'Se quitará @$username de tus cuentas guardadas en este dispositivo. '
          'La cuenta y su perfil no se eliminarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Quitar cuenta'),
          ),
        ],
      ),
    );
    if (shouldForget != true || !mounted) return;

    final accountId = account['id'] as String;
    setState(() => _forgettingAccounts.add(accountId));
    try {
      await DBService.forgetAccount(accountId);
      if (!mounted) return;
      setState(() {
        _accounts.removeWhere((saved) => saved['id'] == accountId);
        _forgettingAccounts.remove(accountId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('@$username se quitó de tus cuentas guardadas.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _forgettingAccounts.remove(accountId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo quitar la cuenta: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loadError != null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _isLoading ? null : _reloadAccounts,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Cambiar de cuenta',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_isLoading && _accounts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          for (final account in _accounts)
            ListTile(
              leading: CircleAvatar(
                backgroundImage: account['profile_photo'] is Uint8List
                    ? MemoryImage(account['profile_photo'] as Uint8List)
                    : null,
                child: account['profile_photo'] is Uint8List
                    ? null
                    : Text(
                        ((account['display_name'] as String).trim().isNotEmpty
                                    ? account['display_name'] as String
                                    : account['username'] as String)
                                .characters
                                .firstOrNull
                                ?.toUpperCase() ??
                            '?',
                      ),
              ),
              title: Text(
                (account['display_name'] as String).trim().isNotEmpty
                    ? account['display_name'] as String
                    : '@${account['username']}',
              ),
              subtitle: Text('@${account['username']}'),
              trailing: account['is_current'] == true
                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                  : IconButton(
                      tooltip: 'Quitar cuenta guardada',
                      icon: _forgettingAccounts.contains(account['id'])
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.close),
                      onPressed: _forgettingAccounts.contains(account['id'])
                          ? null
                          : () => _forget(account),
                    ),
              onTap:
                  account['is_current'] == true ||
                      _forgettingAccounts.contains(account['id'])
                  ? null
                  : () => widget.onSwitch(account),
            ),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.add)),
            title: const Text('Agregar otra cuenta'),
            onTap: widget.onAdd,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MODELOS DE DATOS
// ─────────────────────────────────────────────
