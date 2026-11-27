import 'package:flutter/material.dart';
import '../servicio_bd.dart';
import '../modelos/imagen_perfil.dart';
import '../tema/tema_korulab.dart';
import '../widgets/ui_koru.dart';
import '../modelos/modelos_discusion.dart';
import '../widgets/boton_inicio.dart';

class DiscussionPage extends StatefulWidget {
  final DiscussionSpace space;
  final String username;
  final String displayName;
  final String userRole;
  final ImagenPerfil? authorPhoto;
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

  Widget _authorRow(
    ThemeData theme, {
    required String name,
    required String handle,
    required String role,
    required ImagenPerfil? photo,
    double radius = 20,
    Widget? trailing,
  }) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => openPublicProfile(
            context,
            handle: handle,
            name: name,
            photo: photo,
          ),
          child: KoruAvatar(image: photo?.provider, name: name, radius: radius),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  RoleBadge(role),
                ],
              ),
              if (handle.isNotEmpty)
                Text(
                  '@$handle',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final space = widget.space;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discusión'),
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
          const BotonInicio(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _authorRow(
                          theme,
                          name: space.author,
                          handle: space.authorHandle,
                          role: space.authorRole,
                          photo: space.authorPhoto,
                          radius: 22,
                        ),
                        const SizedBox(height: 16),
                        Text(space.title, style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text(
                          space.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SectionTitle(
                  space.replies.length == 1
                      ? '1 respuesta'
                      : '${space.replies.length} respuestas',
                ),
                if (space.replies.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        IconTile(
                          icon: Icons.forum_rounded,
                          color: context.koru.agua,
                          size: 56,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Todavía no hay respuestas.\nSé el primero en participar.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final reply in space.replies) _replyBubble(theme, reply),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'Escribe una respuesta...',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _submitReply,
                      icon: const Icon(Icons.send_rounded),
                      tooltip: 'Responder',
                      style: IconButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _replyBubble(ThemeData theme, DiscussionReply reply) {
    final canManageReply = _canManageReply(reply);
    final mine =
        DBService.normalizeUsername(reply.authorHandle) ==
        DBService.normalizeUsername(widget.username);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 14),
        decoration: BoxDecoration(
          color: mine
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(KoruRadius.l),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _authorRow(
              theme,
              name: reply.author,
              handle: reply.authorHandle,
              role: reply.authorRole,
              photo: reply.authorPhoto,
              radius: 16,
              trailing: canManageReply
                  ? PopupMenuButton<String>(
                      tooltip: 'Administrar comentario',
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 42, right: 10),
              child: Text(reply.message, style: theme.textTheme.bodyLarge),
            ),
          ],
        ),
      ),
    );
  }
}
