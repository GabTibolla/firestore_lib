import 'package:cloud_firestore/cloud_firestore.dart';

import 'search_criterio.dart';

class QueryFilter {
  late CollectionReference _collection;

  QueryFilter(String collectionName) {
    _collection = FirebaseFirestore.instance.collection(collectionName);
  }

  Future<QuerySnapshot> getQuerySnapshot(SearchCriterio criterio, [GetOptions? source]) async {
    Query query = getQueryWhere(criterio);

    QuerySnapshot snapshot = await query.get(source);
    return snapshot;
  }

  Query getQueryWhere(SearchCriterio criterio) {
    Query query = _collection;

    List<Filter> andFilters = [];
    List<Filter> orGroup = [];

    for (var item in criterio.criterioItem) {
      Filter filter = _createFirebaseFilter(item);

      if (item.logicalOperator == LogicalOperator.or) {
        orGroup.add(filter);
      } else {
        if (orGroup.isNotEmpty) {
          orGroup.add(filter);

          andFilters.add(_combineOr(orGroup));

          orGroup.clear();
        } else {
          andFilters.add(filter);
        }
      }
    }

    if (orGroup.isNotEmpty) {
      andFilters.add(_combineOr(orGroup));
    }

    if (andFilters.isNotEmpty) {
      query = query.where(_combineAnd(andFilters));
    }

    for (var item in criterio.order) {
      query = query.orderBy(item.field, descending: item.desc);
    }

    return query.limit(criterio.limit);
  }

  Filter _combineAnd(List<Filter> filters) {
    if (filters.length == 1) {
      return filters.first;
    }

    return Filter.and(filters[0], _combineAnd(filters.sublist(1)));
  }

  Filter _combineOr(List<Filter> filters) {
    if (filters.length == 1) {
      return filters.first;
    }

    return Filter.or(filters[0], _combineOr(filters.sublist(1)));
  }

  Filter _createFirebaseFilter(SearchCriterioItem item) {
    switch (item.compare) {
      case CompareEnum.isEqualTo:
        return Filter(item.fieldName, isEqualTo: item.value);

      case CompareEnum.isNotEqualTo:
        return Filter(item.fieldName, isNotEqualTo: item.value);

      case CompareEnum.arrayContains:
        return Filter(item.fieldName, arrayContains: item.value);
    }
  }
}
