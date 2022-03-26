extension IterableExtensions<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    final list = where(test);
    return list.isEmpty ? null : list.first;
  }

    bool all(bool Function(T) f) {
      for (final x in this) {
        if (!f(x)) {
          return false;
        }
      }
      return true;
    }
}

extension IterableIterableExtensions<T> on Iterable<Iterable<T>> {
  List<T1> selectMany<T1>(T1 Function(T element) test) {
    List<T1> result = [];
    for (final t in this) {
      final i = t.map(test);
      for (final ii in i) {
        result.add(ii);
      }
    }
    return result;
  }
}

extension MapExtension<TKey, TValue> on Map<TKey, TValue> {
  TValue? lookup(TKey key) => containsKey(key) ? this[key] : null;
}

extension MapExtensions<TValue> on Map<String, TValue> {
  TValue? lookupNested(String key) {
    if (key.isEmpty) {
      throw Exception('Key is empty');
    }

    final keys = key.split(':').map((x) => x.trim()).toList();
    Map<String, dynamic> current = this;

    for (int i = 0; i < keys.length - 1; i++) {
      final currKey = keys[i];
      final curr = current[currKey] as Map<String, dynamic>?;

      if (curr == null) {
        return null;
      }

      current = curr;
    }

    return current.lookup(keys.last);
  }
}

extension IterableToMapExtension<TKey, TValue> on Iterable<MapEntry<TKey, TValue>> {
  Map<TKey, TValue> toMap() {
    return Map.fromEntries(this);
  }
}

extension ListExtensions<T> on List<T> {
    List<List<T>> pack(int packSize) {
      final packsCount = (this.length / packSize).ceil();
      final List<List<T>> result =
          List.generate(packsCount, (_) => <T>[]);

      int currentPack = 0;
      for (int i = 0; i < this.length; i++) {
        result[currentPack].add(this[i]);
        final num = i + 1;
        if (num % packSize == 0) {
            currentPack++;
        }
      }

      return result;
    }
}

extension StringExtensions on String {
int getClosingBracketIndex(int openIndex) {
    int result = openIndex;

    int opened = 0, closed = 0;
    for (int i = openIndex; i < length; i++) {
      result = i;
      if (this[i] == '{') {
        opened++;
      }
      if (this[i] == '}') {
        closed++;
      }
      if (opened == closed) {
        break;
      }
    }

    return result;
  }
}