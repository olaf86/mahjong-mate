import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/rule_category.dart';
import '../domain/rule_item.dart';
import '../domain/rule_set.dart';
import '../domain/rule_set_visibility.dart';

class RuleSetRepository {
  RuleSetRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('rule_sets');

  Stream<List<RuleSet>> watchRuleSets({required String deviceId}) {
    final publicStream = _collection
        .where('visibility', isEqualTo: 'public')
        .snapshots()
        .map(_mapQuery);
    final ownedStream = _collection
        .where('ownerDeviceId', isEqualTo: deviceId)
        .snapshots()
        .map(_mapQuery);

    return _mergeStreams(publicStream, ownedStream);
  }

  List<RuleSet> _mapQuery(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.map(_mapDoc).toList();
  }

  RuleSet _mapDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final itemsRaw = data['items'];
    final items = <RuleItem>[];
    if (itemsRaw is List) {
      for (final item in itemsRaw) {
        if (item is Map<String, dynamic>) {
          items.add(
            RuleItem(
              id: _stringValue(item['id'], fallback: _randomId('item')),
              category: _parseCategory(item['category']),
              title: _stringValue(item['title'], fallback: '未設定'),
              description: _stringValue(item['description'], fallback: ''),
              priority: _intValue(item['priority']),
            ),
          );
        }
      }
    }

    return RuleSet(
      id: doc.id,
      name: _stringValue(data['name'], fallback: '名称未設定'),
      description: _stringValue(data['description'], fallback: ''),
      ownerName: _stringValue(data['ownerName'], fallback: 'Mahjong Mate'),
      ownerDeviceId: _stringValueOrNull(data['ownerDeviceId']),
      shareCode: _stringValueOrNull(data['shareCode']),
      visibility: _parseVisibility(data['visibility']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      items: items,
    );
  }

  Stream<List<RuleSet>> _mergeStreams(
    Stream<List<RuleSet>> publicStream,
    Stream<List<RuleSet>> ownedStream,
  ) {
    final controller = StreamController<List<RuleSet>>();
    var latestPublic = const <RuleSet>[];
    var latestOwned = const <RuleSet>[];

    void emit() {
      final merged = <String, RuleSet>{};
      for (final ruleSet in [...latestPublic, ...latestOwned]) {
        merged[ruleSet.id] = ruleSet;
      }
      final list = merged.values.toList();
      list.sort(_sortRuleSets);
      controller.add(list);
    }

    final publicSub = publicStream.listen(
      (data) {
        latestPublic = data;
        emit();
      },
      onError: controller.addError,
    );
    final ownedSub = ownedStream.listen(
      (data) {
        latestOwned = data;
        emit();
      },
      onError: controller.addError,
    );

    controller.onCancel = () {
      publicSub.cancel();
      ownedSub.cancel();
    };

    return controller.stream;
  }

  int _sortRuleSets(RuleSet a, RuleSet b) {
    final aTime = a.updatedAt?.millisecondsSinceEpoch ?? 0;
    final bTime = b.updatedAt?.millisecondsSinceEpoch ?? 0;
    if (aTime != bTime) {
      return bTime.compareTo(aTime);
    }
    return a.name.compareTo(b.name);
  }

  RuleCategory _parseCategory(Object? value) {
    if (value is String) {
      for (final category in RuleCategory.values) {
        if (category.name == value) {
          return category;
        }
      }
    }
    return RuleCategory.basic;
  }

  RuleSetVisibility _parseVisibility(Object? value) {
    if (value is String) {
      for (final visibility in RuleSetVisibility.values) {
        if (visibility.name == value) {
          return visibility;
        }
      }
    }
    return RuleSetVisibility.private;
  }

  DateTime? _parseTimestamp(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }

  String _stringValue(Object? value, {required String fallback}) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return fallback;
  }

  String? _stringValueOrNull(Object? value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  int _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    return 0;
  }

  String _randomId(String prefix) {
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}';
  }
}
