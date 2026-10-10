import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../db_service.dart';
import '../public_profile_page.dart';

class DiscussionReply {
  final int? id;
  final String author;
  final String authorHandle;
  final String authorRole;
  final Uint8List? authorPhoto;
  final String message;
  final DateTime createdAt;

  DiscussionReply({
    this.id,
    required this.author,
    this.authorHandle = '',
    this.authorRole = DBService.roleStudent,
    this.authorPhoto,
    required this.message,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class DiscussionSpace {
  final int? id;
  String title;
  String description;
  final bool isPinned;
  final String author;
  final String authorHandle;
  final String authorRole;
  final Uint8List? authorPhoto;
  final DateTime createdAt;
  final List<DiscussionReply> replies;

  DiscussionSpace({
    this.id,
    required this.title,
    required this.description,
    this.isPinned = false,
    required this.author,
    this.authorHandle = '',
    this.authorRole = DBService.roleStudent,
    this.authorPhoto,
    DateTime? createdAt,
    List<DiscussionReply>? replies,
  }) : createdAt = createdAt ?? DateTime.now(),
       replies = replies ?? [];
}

// Abre el perfil público de un autor de Korublog al tocar su foto.
void openPublicProfile(
  BuildContext context, {
  required String handle,
  required String name,
  Uint8List? photo,
}) {
  if (handle.isEmpty) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PublicProfilePage(
        username: handle,
        fallbackName: name,
        fallbackPhoto: photo,
      ),
    ),
  );
}

// ─────────────────────────────────────────────
//  PÁGINAS PRINCIPALES
// ─────────────────────────────────────────────
