import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../servicio_bd.dart';
import '../modelos/modelos_curso.dart';
import '../modelos/modelos_discusion.dart';

class DiscussionPage extends StatefulWidget {
  final DiscussionSpace space;
  final String username;
  final String displayName;
  final String userRole;
  final Uint8List? authorPhoto;
  final bool isAdmin;
  final bool isTeacher;

  const DiscussionPage({
    required this.space,
    required this.username,
    required this.displayName,
    required this.userRole,
    required this.authorPhoto,
    required this.isAdmin,
    required this.isTeacher,
    super.key,
  });

  @override
  State<DiscussionPage> createState() => _DiscussionPageState();
}

class _DiscussionPageState extends State<DiscussionPage> {
  final _replyController = TextEditingController();

  bool get _canManageSpace =>
      widget.isAdmin ||
      widget.isTeacher ||
      DBService.normalizeUsername(widget.space.authorHandle) ==
          DBService.normalizeUsername(widget.username);

  bool _canManageReply(DiscussionReply reply) =>
      widget.isAdmin ||
      widget.isTeacher ||
      DBService.normalizeUsername(reply.authorHandle) ==
          DBService.normalizeUsername(widget.username);

  Future<void> _submitReply() async {
    final message = _replyController.text.trim();
    if (message.isEmpty) return;
    final discussionId = widget.space.id;
    if (discussionId == null) return;
    try {
      final replyId = await DBService.addDiscussionReply(
        discussionId: discussionId,
        author: widget.displayName,
        message: message,
        authorHandle: widget.username,
      );
      if (!mounted) return;
      setState(() {
        widget.space.replies.add(
          DiscussionReply(
            id: replyId,
            author: widget.displayName,
            authorHandle: widget.username,
            authorRole: widget.userRole,
            authorPhoto: widget.authorPhoto,
            message: message,
          ),
        );
        _replyController.clear();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo publicar el comentario.')),
        );
      }
    }
  }

  Future<void> _editSpace() async {
    final titleController = TextEditingController(text: widget.space.title);
    final descriptionController = TextEditingController(
      text: widget.space.description,
    );
    final values = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar publicación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: descriptionController,
              maxLength: 180,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              final description = descriptionController.text.trim();
              if (title.isEmpty || description.isEmpty) return;
              Navigator.pop(dialogContext, [title, description]);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (!mounted || values == null || widget.space.id == null) return;

    final updated = await DBService.updateDiscussionSpace(
      discussionId: widget.space.id!,
      requesterUsername: widget.username,
      title: values[0],
      description: values[1],
    );
    if (!mounted) return;
    if (!updated) {
      _showDiscussionMessage('No tienes permiso para editar esta publicación.');
      return;
    }
    setState(() {
      widget.space.title = values[0];
      widget.space.description = values[1];
    });
  }

  Future<void> _deleteSpace() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text(
          'También se eliminarán sus comentarios. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || widget.space.id == null) return;
    final deleted = await DBService.deleteDiscussionSpace(
      discussionId: widget.space.id!,
      requesterUsername: widget.username,
    );
    if (!mounted) return;
    if (!deleted) {
      _showDiscussionMessage(
        'No tienes permiso para eliminar esta publicación.',
      );
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> _editReply(DiscussionReply reply) async {
    if (reply.id == null) return;
    final controller = TextEditingController(text: reply.message);
    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar comentario'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Comentario',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (!mounted || message == null) return;
    final updated = await DBService.updateDiscussionReply(
      replyId: reply.id!,
      requesterUsername: widget.username,
      message: message,
    );
    if (!mounted) return;
    if (!updated) {
      _showDiscussionMessage('No tienes permiso para editar este comentario.');
      return;
    }
    final index = widget.space.replies.indexWhere(
      (item) => item.id == reply.id,
    );
    if (index >= 0) {
      setState(() {
        widget.space.replies[index] = DiscussionReply(
          id: reply.id,
          author: reply.author,
          authorHandle: reply.authorHandle,
          authorPhoto: reply.authorPhoto,
          message: message,
          createdAt: reply.createdAt,
        );
      });
    }
  }

  Future<void> _deleteReply(DiscussionReply reply) async {
    if (reply.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: const Text('¿Quieres eliminar este comentario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final deleted = await DBService.deleteDiscussionReply(
      replyId: reply.id!,
      requesterUsername: widget.username,
    );
    if (!mounted) return;
    if (!deleted) {
      _showDiscussionMessage(
        'No tienes permiso para eliminar este comentario.',
      );
      return;
    }
    setState(() {
      widget.space.replies.removeWhere((item) => item.id == reply.id);
    });
  }

  void _showDiscussionMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Espacio de discusión'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          if (_canManageSpace)
            PopupMenuButton<String>(
              tooltip: 'Administrar publicación',
              onSelected: (action) {
                if (action == 'edit') _editSpace();
                if (action == 'delete') _deleteSpace();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar publicación')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Eliminar publicación'),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.space.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.space.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => openPublicProfile(
                        context,
                        handle: widget.space.authorHandle,
                        name: widget.space.author,
                        photo: widget.space.authorPhoto,
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: widget.space.authorPhoto == null
                            ? null
                            : MemoryImage(widget.space.authorPhoto!),
                        child: widget.space.authorPhoto == null
                            ? Icon(
                                Icons.person,
                                color: theme.colorScheme.onPrimaryContainer,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.space.author,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (widget.space.authorHandle.isNotEmpty)
                            Text(
                              '@${widget.space.authorHandle}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          Text(
                            DBService.roleLabel(widget.space.authorRole),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Respuestas (${widget.space.replies.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.space.replies.isEmpty)
                  Text(
                    'Todavía no hay respuestas. Sé el primero en participar.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ...widget.space.replies.map((reply) {
                    final canManageReply = _canManageReply(reply);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.65),
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: () => openPublicProfile(
                            context,
                            handle: reply.authorHandle,
                            name: reply.author,
                            photo: reply.authorPhoto,
                          ),
                          child: CircleAvatar(
                            backgroundImage: reply.authorPhoto == null
                                ? null
                                : MemoryImage(reply.authorPhoto!),
                            backgroundColor: theme.colorScheme.primary
                                .withOpacity(0.2),
                            child: reply.authorPhoto == null
                                ? Icon(
                                    Icons.person,
                                    color: theme.colorScheme.primaryContainer,
                                  )
                                : null,
                          ),
                        ),
                        title: Text(
                          reply.author,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(reply.message),
                              if (reply.authorHandle.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '@${reply.authorHandle}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              Text(
                                DBService.roleLabel(reply.authorRole),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: canManageReply
                            ? PopupMenuButton<String>(
                                tooltip: 'Administrar comentario',
                                onSelected: (action) {
                                  if (action == 'edit') _editReply(reply);
                                  if (action == 'delete') _deleteReply(reply);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar comentario'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Eliminar comentario'),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  }),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Escribe una respuesta...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _submitReply,
                    icon: const Icon(Icons.send),
                    tooltip: 'Responder',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

