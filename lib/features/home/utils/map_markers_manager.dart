import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../data/models/issue_model.dart';

/// Manages issue markers on the map
class MapMarkersManager {
  static const String _pinAssetPath = 'assets/icons/map_issue_pin.png';

  final Map<String, PointAnnotation> _annotations = {};
  final Map<String, List<IssueModel>> _groupIssuesCache = {};
  final Map<String, String> _annotationToGroupKey = {};
  final Map<String, String> _groupSignatureCache = {};
  final MapboxMap? mapboxMap;
  final Function(List<IssueModel> issues)? onAnnotationTap;
  PointAnnotationManager? _pointManager;
  Cancelable? _tapCancelable;
  Uint8List? _pinImageBytes;

  MapMarkersManager({required this.mapboxMap, this.onAnnotationTap});

  String _locationKey(double lat, double lng) =>
      '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';

  String _buildGroupSignature(List<IssueModel> issues) {
    final ids =
        issues
            .map((issue) => issue.id ?? '')
            .where((id) => id.isNotEmpty)
            .toList()
          ..sort();
    return ids.join('|');
  }

  Future<Uint8List?> _loadPinImageBytes() async {
    if (_pinImageBytes != null) return _pinImageBytes;
    try {
      final byteData = await rootBundle.load(_pinAssetPath);
      _pinImageBytes = byteData.buffer.asUint8List();
      return _pinImageBytes;
    } catch (e) {
      debugPrint('[Pin Asset Load Error]: $e');
      return null;
    }
  }

  /// Re-register style image and redraw markers after style reload.
  Future<void> onStyleReloaded() async {
    final map = mapboxMap;
    if (map == null) return;

    final groupedIssuesSnapshot = <String, List<IssueModel>>{};
    for (final entry in _groupIssuesCache.entries) {
      groupedIssuesSnapshot[entry.key] = List<IssueModel>.from(entry.value);
    }

    _tapCancelable?.cancel();
    _tapCancelable = null;
    _pointManager = null;
    _annotations.clear();
    _annotationToGroupKey.clear();
    _groupSignatureCache.clear();

    for (final entry in groupedIssuesSnapshot.entries) {
      final key = entry.key;
      final issuesAtLocation = entry.value;
      final annotation = await _createGroupAnnotation(key, issuesAtLocation);
      if (annotation != null) {
        _annotations[key] = annotation;
        _groupIssuesCache[key] = List<IssueModel>.from(issuesAtLocation);
        _groupSignatureCache[key] = _buildGroupSignature(issuesAtLocation);
      }
    }
  }

  Future<PointAnnotationManager?> _getPointManager() async {
    final map = mapboxMap;
    if (map == null) return null;

    if (_pointManager != null) return _pointManager;

    final manager = await map.annotations.createPointAnnotationManager();
    _tapCancelable = manager.tapEvents(
      onTap: (PointAnnotation annotation) {
        final groupKey = _annotationToGroupKey[annotation.id];
        final issues = groupKey != null ? _groupIssuesCache[groupKey] : null;
        if (issues != null && issues.isNotEmpty && onAnnotationTap != null) {
          onAnnotationTap!(issues);
        }
      },
    );

    _pointManager = manager;
    return manager;
  }

  /// Get all currently displayed annotations
  Map<String, PointAnnotation> get annotations =>
      Map.unmodifiable(_annotations);

  /// Update markers based on list of issues
  Future<void> updateMarkers(List<QueryDocumentSnapshot> docs) async {
    final map = mapboxMap;
    if (map == null) return;
    final manager = await _getPointManager();
    if (manager == null) return;

    // Filter issues with valid locations
    final validIssues =
        docs
            .where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['location'] is Map<String, dynamic>;
            })
            .map((doc) => IssueModel.fromFirestore(doc))
            .where((issue) => issue.location != null)
            .toList();

    final groupedIssues = <String, List<IssueModel>>{};
    for (final issue in validIssues) {
      final lat = (issue.location!['latitude'] as num?)?.toDouble();
      final lng = (issue.location!['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      final key = _locationKey(lat, lng);
      groupedIssues.putIfAbsent(key, () => []).add(issue);
    }

    final currentKeys = groupedIssues.keys.toSet();

    // Remove annotations for issues that no longer exist
    final toRemove =
        _annotations.keys.where((key) => !currentKeys.contains(key)).toList();
    for (final key in toRemove) {
      final annotation = _annotations.remove(key);
      if (annotation != null) {
        try {
          await manager.delete(annotation);
        } catch (e) {
          debugPrint('[Annotation Delete Error]: $e');
        }
        _annotationToGroupKey.remove(annotation.id);
      }
      _groupIssuesCache.remove(key);
      _groupSignatureCache.remove(key);
    }

    // Add or refresh grouped annotations
    for (final entry in groupedIssues.entries) {
      final key = entry.key;
      final issuesAtLocation = entry.value;
      final existing = _annotations[key];
      final nextSignature = _buildGroupSignature(issuesAtLocation);
      final currentSignature = _groupSignatureCache[key];

      if (existing == null) {
        final annotation = await _createGroupAnnotation(key, issuesAtLocation);
        if (annotation != null) {
          _annotations[key] = annotation;
          _groupIssuesCache[key] = List<IssueModel>.from(issuesAtLocation);
          _groupSignatureCache[key] = nextSignature;
        }
        continue;
      }

      final shouldRefresh = currentSignature != nextSignature;

      if (shouldRefresh) {
        try {
          await manager.delete(existing);
        } catch (e) {
          debugPrint('[Annotation Refresh Delete Error]: $e');
        }
        _annotationToGroupKey.remove(existing.id);

        final refreshed = await _createGroupAnnotation(key, issuesAtLocation);
        if (refreshed != null) {
          _annotations[key] = refreshed;
          _groupIssuesCache[key] = List<IssueModel>.from(issuesAtLocation);
          _groupSignatureCache[key] = nextSignature;
        }
      } else {
        _groupIssuesCache[key] = List<IssueModel>.from(issuesAtLocation);
      }
    }
  }

  /// Create a single grouped annotation for issues at the same location
  Future<PointAnnotation?> _createGroupAnnotation(
    String groupKey,
    List<IssueModel> issues,
  ) async {
    final manager = await _getPointManager();
    if (manager == null) return null;

    if (issues.isEmpty) return null;
    final pinImageBytes = await _loadPinImageBytes();
    if (pinImageBytes == null || pinImageBytes.isEmpty) return null;

    final leadIssue = issues.first;

    final lat = (leadIssue.location!['latitude'] as num?)?.toDouble();
    final lng = (leadIssue.location!['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    try {
      final annotation = await manager.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          image: pinImageBytes,
          iconAnchor: IconAnchor.BOTTOM,
          iconSize: 0.72,
        ),
      );

      _annotationToGroupKey[annotation.id] = groupKey;

      return annotation;
    } catch (e) {
      debugPrint('[Annotation Error]: $e');
      return null;
    }
  }

  /// Clear all annotations
  Future<void> clearAll() async {
    final manager = _pointManager;
    if (manager != null) {
      try {
        await manager.deleteAll();
      } catch (e) {
        debugPrint('[Annotation Clear Error]: $e');
      }
    }
    _tapCancelable?.cancel();
    _tapCancelable = null;
    _pointManager = null;
    _annotations.clear();
    _groupIssuesCache.clear();
    _annotationToGroupKey.clear();
    _groupSignatureCache.clear();
  }
}
