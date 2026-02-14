import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/rule_category.dart';
import '../domain/rule_item.dart';
import '../domain/rule_set.dart';
import '../domain/rule_set_rules.dart';
import '../domain/rule_set_visibility.dart';

class RuleSetRepository {
  RuleSetRepository(this._firestore);

  final FirebaseFirestore _firestore;
  final Random _random = Random();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('rule_sets');
  CollectionReference<Map<String, dynamic>> _followsCollection(String ownerUid) =>
      _firestore.collection('users').doc(ownerUid).collection('follows');

  Stream<List<RuleSet>> watchRuleSets({required String ownerUid}) {
    final publicStream = _collection
        .where('visibility', isEqualTo: 'public')
        .snapshots()
        .map(_mapQuery);
    final ownedStream = _collection
        .where('ownerUid', isEqualTo: ownerUid)
        .snapshots()
        .map(_mapQuery);

    return _mergeStreams(publicStream, ownedStream);
  }

  Stream<List<String>> watchFollowedRuleSetIds({required String ownerUid}) {
    return _followsCollection(ownerUid)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Stream<List<RuleSet>> watchFollowedRuleSets({required String ownerUid}) {
    final controller = StreamController<List<RuleSet>>();
    final docSubs = <String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>{};
    final rulesets = <String, RuleSet>{};
    var orderedIds = <String>[];

    void emit() {
      final list = <RuleSet>[];
      for (final id in orderedIds) {
        final ruleSet = rulesets[id];
        if (ruleSet != null) {
          list.add(ruleSet);
        }
      }
      controller.add(list);
    }

    void updateSubscriptions(List<String> nextIds) {
      final nextSet = nextIds.toSet();
      for (final existing in docSubs.keys.toList()) {
        if (!nextSet.contains(existing)) {
          docSubs[existing]?.cancel();
          docSubs.remove(existing);
          rulesets.remove(existing);
        }
      }
      for (final id in nextIds) {
        if (docSubs.containsKey(id)) continue;
        final sub = _collection.doc(id).snapshots().listen(
          (snapshot) {
            if (!snapshot.exists) {
              rulesets.remove(id);
            } else {
              final data = snapshot.data();
              if (data != null) {
                rulesets[id] = _mapDocFromData(snapshot.id, data);
              }
            }
            emit();
          },
          onError: (_) {
            rulesets.remove(id);
            emit();
          },
        );
        docSubs[id] = sub;
      }
    }

    final followSub = _followsCollection(ownerUid)
        .orderBy('order')
        .snapshots()
        .listen((snapshot) {
      orderedIds = snapshot.docs.map((doc) => doc.id).toList();
      updateSubscriptions(orderedIds);
      emit();
    }, onError: controller.addError);

    controller.onCancel = () {
      followSub.cancel();
      for (final sub in docSubs.values) {
        sub.cancel();
      }
    };

    return controller.stream;
  }

  Future<void> followRuleSet({
    required String ownerUid,
    required String ruleSetId,
  }) async {
    final docRef = _followsCollection(ownerUid).doc(ruleSetId);
    final existing = await docRef.get();
    if (existing.exists) return;
    final snapshot =
        await _followsCollection(ownerUid).orderBy('order', descending: true).limit(1).get();
    final nextOrder = snapshot.docs.isEmpty
        ? 0
        : (snapshot.docs.first.data()['order'] as int? ?? 0) + 1;
    await docRef.set({
      'order': nextOrder,
      'ruleSetId': ruleSetId,
      'followedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unfollowRuleSet({
    required String ownerUid,
    required String ruleSetId,
  }) async {
    await _followsCollection(ownerUid).doc(ruleSetId).delete();
  }

  Future<void> updateFollowOrder({
    required String ownerUid,
    required List<String> orderedRuleSetIds,
  }) async {
    final batch = _firestore.batch();
    for (var i = 0; i < orderedRuleSetIds.length; i++) {
      final id = orderedRuleSetIds[i];
      batch.update(_followsCollection(ownerUid).doc(id), {'order': i});
    }
    await batch.commit();
  }

  Future<RuleSet?> fetchRuleSetByShareCode(String shareCode) async {
    final snapshot =
        await _collection.where('shareCode', isEqualTo: shareCode).limit(1).get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return _mapDoc(snapshot.docs.first);
  }

  Future<RuleSet> createRuleSet({
    required String name,
    required String description,
    required String ownerName,
    required String ownerUid,
    required RuleSetVisibility visibility,
    required List<RuleItem> items,
    RuleSetRules? rules,
  }) async {
    final doc = _collection.doc();
    final shareCode = _ensureShareCode(visibility: visibility, existing: null);
    final now = DateTime.now();

    await doc.set({
      'name': name,
      'description': description,
      'ownerName': ownerName,
      'ownerUid': ownerUid,
      'shareCode': shareCode,
      'visibility': visibility.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'items': items.map(_itemToMap).toList(),
      if (rules != null) 'rules': rules.toMap(),
    });

    return RuleSet(
      id: doc.id,
      name: name,
      description: description,
      ownerName: ownerName,
      ownerUid: ownerUid,
      shareCode: shareCode,
      visibility: visibility,
      updatedAt: now,
      items: items,
      rules: rules,
    );
  }

  Future<void> updateRuleSet({
    required String id,
    required String name,
    required String description,
    required String ownerName,
    required String ownerUid,
    required RuleSetVisibility visibility,
    required List<RuleItem> items,
    required String? shareCode,
    RuleSetRules? rules,
  }) async {
    final doc = _collection.doc(id);
    final nextShareCode = _ensureShareCode(visibility: visibility, existing: shareCode);
    final updatePayload = <String, dynamic>{
      'name': name,
      'description': description,
      'ownerName': ownerName,
      'ownerUid': ownerUid,
      'shareCode': nextShareCode,
      'visibility': visibility.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'items': items.map(_itemToMap).toList(),
    };
    if (rules != null) {
      updatePayload['rules'] = rules.toMap();
    }
    await doc.update(updatePayload);
  }

  Future<void> deleteRuleSet(String id) async {
    await _collection.doc(id).delete();
  }

  List<RuleSet> _mapQuery(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.map(_mapDoc).toList();
  }

  RuleSet _mapDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final items = _parseItems(data['items']);
    return _mapDocFromData(doc.id, data, items: items);
  }

  RuleSet _mapDocFromData(
    String id,
    Map<String, dynamic> data, {
    List<RuleItem>? items,
  }) {
    final resolvedItems = items ?? _parseItems(data['items']);
    return RuleSet(
      id: id,
      name: _stringValue(data['name'], fallback: '名称未設定'),
      description: _stringValue(data['description'], fallback: ''),
      ownerName: _stringValue(data['ownerName'], fallback: 'Mahjong Mate'),
      ownerUid: _stringValueOrNull(data['ownerUid']),
      shareCode: _stringValueOrNull(data['shareCode']),
      visibility: _parseVisibility(data['visibility']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      items: resolvedItems,
      rules: RuleSetRules.fromMap(data['rules']),
    );
  }

  List<RuleItem> _parseItems(Object? itemsRaw) {
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
    return items;
  }

  Map<String, dynamic> _itemToMap(RuleItem item) {
    return {
      'id': item.id,
      'category': item.category.name,
      'title': item.title,
      'description': item.description,
      'priority': item.priority,
    };
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

  String? _ensureShareCode({
    required RuleSetVisibility visibility,
    required String? existing,
  }) {
    if (visibility != RuleSetVisibility.public) {
      return null;
    }
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    return 'MJM-${_generateShareCode()}';
  }

  String _generateShareCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final buffer = StringBuffer();
    for (var i = 0; i < 4; i++) {
      buffer.write(chars[_random.nextInt(chars.length)]);
    }
    return buffer.toString();
  }
}
