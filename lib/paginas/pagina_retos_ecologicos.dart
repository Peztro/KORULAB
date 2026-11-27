import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../servicio_bd.dart';
import '../tema/tema_korulab.dart';
import '../widgets/ui_koru.dart';

// ─────────────────────────────────────────────
//  COURSE CARD
// ─────────────────────────────────────────────
// Catálogo de cursos y actividades disponibles en Koruclases
class EcoChallengesPage extends StatefulWidget {
  final String username;

  const EcoChallengesPage({super.key, required this.username});

  @override
  State<EcoChallengesPage> createState() => _EcoChallengesPageState();
}

class _EcoChallengesPageState extends State<EcoChallengesPage> {
  static const _challenges =
      <({String id, String title, String description, IconData icon})>[
        (
          id: 'bottle',
          title: 'Usa una botella reutilizable',
          description: 'Evita comprar una botella desechable hoy.',
          icon: Icons.water_drop_rounded,
        ),
        (
          id: 'recycle',
          title: 'Separa tus residuos',
          description: 'Clasifica papel, envases y residuos orgánicos.',
          icon: Icons.recycling_rounded,
        ),
        (
          id: 'lights',
          title: 'Ahorra energía',
          description: 'Apaga las luces y desconecta lo que no uses.',
          icon: Icons.bolt_rounded,
        ),
        (
          id: 'walk',
          title: 'Elige movilidad sostenible',
          description:
              'Camina, usa bicicleta o transporte público en un trayecto.',
          icon: Icons.directions_bike_rounded,
        ),
        (
          id: 'food',
          title: 'Reduce el desperdicio de comida',
          description: 'Planifica una comida con lo que ya tienes en casa.',
          icon: Icons.restaurant_rounded,
        ),
        (
          id: 'reuse',
          title: 'Dale otro uso a un objeto',
          description:
              'Reutiliza un envase, repara algo o comparte lo que no necesitas.',
          icon: Icons.handyman_rounded,
        ),
      ];

  Color _colorFor(BuildContext context, String id) {
    final koru = context.koru;
    return switch (id) {
      'bottle' => koru.agua,
      'lights' => koru.oro,
      'walk' => koru.tierra,
      'food' => koru.fuego,
      _ => koru.hoja,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    return Scaffold(
      appBar: AppBar(title: const Text('Retos ekológicos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: koru.degradadoHero,
              borderRadius: BorderRadius.circular(KoruRadius.xl),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Un reto a tu ritmo',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: koru.textoHero,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pequeñas acciones cotidianas también ayudan a cuidar '
                        'el planeta. Anota cada avance en tu diario.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: koru.textoHero.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.emoji_events_rounded,
                  size: 52,
                  color: koru.textoHero.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SectionTitle('${_challenges.length} retos disponibles'),
          for (final challenge in _challenges)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FeatureCard(
                title: challenge.title,
                subtitle: challenge.description,
                icon: challenge.icon,
                color: _colorFor(context, challenge.id),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 16,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Diario',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EcoChallengeJournalPage(
                      username: widget.username,
                      challengeId: challenge.id,
                      challengeTitle: challenge.title,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class EcoChallengeJournalPage extends StatefulWidget {
  final String username;
  final String challengeId;
  final String challengeTitle;

  const EcoChallengeJournalPage({
    super.key,
    required this.username,
    required this.challengeId,
    required this.challengeTitle,
  });

  @override
  State<EcoChallengeJournalPage> createState() =>
      _EcoChallengeJournalPageState();
}

class _EcoChallengeJournalPageState extends State<EcoChallengeJournalPage> {
  final _imagePicker = ImagePicker();
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;
  bool _loadError = false;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
      _loadError = false;
    });
    try {
      final entries = await DBService.getEcoJournalEntries(
        username: widget.username,
        challengeId: widget.challengeId,
      );
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = true;
      });
    }
  }

  Future<void> _addEntry() async {
    final noteController = TextEditingController();
    final photos = <Uint8List>[];
    try {
      final shouldSave = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nueva nota del día',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¿Qué hiciste hoy y cómo ayudó a este reto?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    minLines: 4,
                    maxLines: 7,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: 'Tu experiencia',
                      hintText: 'Escribe los detalles de tu proceso...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final images = await _imagePicker.pickMultiImage(
                          maxWidth: 1600,
                          maxHeight: 1600,
                          imageQuality: 85,
                        );
                        for (final image in images) {
                          photos.add(await image.readAsBytes());
                        }
                        if (sheetContext.mounted) {
                          setModalState(() {});
                        }
                      } catch (_) {
                        if (mounted)
                          _showMessage('No se pudieron cargar las fotos.');
                      }
                    },
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      photos.isEmpty
                          ? 'Agregar fotos'
                          : 'Agregar más fotos (${photos.length})',
                    ),
                  ),
                  if (photos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 94,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                photos[index],
                                width: 94,
                                height: 94,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: IconButton(
                                onPressed: () =>
                                    setModalState(() => photos.removeAt(index)),
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: Colors.white,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      if (noteController.text.trim().isEmpty &&
                          photos.isEmpty) {
                        _showMessage('Escribe una nota o agrega una foto.');
                        return;
                      }
                      Navigator.of(sheetContext).pop(true);
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar en mi diario'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (shouldSave != true) return;

      await DBService.addEcoJournalEntry(
        username: widget.username,
        challengeId: widget.challengeId,
        note: noteController.text,
        photos: photos,
      );
      if (!mounted) return;
      await _loadEntries();
      _showMessage('Tu entrada quedó guardada.');
    } catch (_) {
      if (mounted)
        _showMessage('No se pudo guardar la entrada. Inténtalo de nuevo.');
    }
  }

  Future<void> _deleteEntry(int entryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar entrada'),
        content: const Text('¿Quieres eliminar esta nota y sus fotos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await DBService.deleteEcoJournalEntry(
        entryId: entryId,
        username: widget.username,
      );
      await _loadEntries();
    } catch (_) {
      if (mounted) _showMessage('No se pudo eliminar la entrada.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return value;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Diario del reto')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntry,
        icon: const Icon(Icons.add),
        label: const Text('Nueva entrada'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No se pudo cargar tu diario.'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _loadEntries,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                PageHeader(
                  title: widget.challengeTitle,
                  subtitle:
                      'Registra tus acciones, reflexiones y fotos día a día.',
                ),
                if (_entries.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          IconTile(
                            icon: Icons.auto_stories_rounded,
                            color: context.koru.hoja,
                            size: 64,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Tu diario está listo',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Agrega una nota o una foto para contar cómo '
                            'avanzas con este reto.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final entry in _entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _JournalEntryCard(
                        date: _formatDate(entry['created_at'] as String),
                        note: entry['note'] as String,
                        photos: entry['photos'] as List<Uint8List>,
                        onDelete: () => _deleteEntry(entry['id'] as int),
                      ),
                    ),
              ],
            ),
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({
    required this.date,
    required this.note,
    required this.photos,
    required this.onDelete,
  });

  final String date;
  final String note;
  final List<Uint8List> photos;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_rounded, size: 18, color: koru.hoja),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Eliminar entrada',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            if (note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(note, style: theme.textTheme.bodyLarge),
              ),
            if (photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(KoruRadius.m),
                    child: Image.memory(
                      photos[index],
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
