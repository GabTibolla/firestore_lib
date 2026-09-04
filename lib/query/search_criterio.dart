import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'query_filter.dart';

enum CompareEnum { isEqualTo, isNotEqualTo, arrayContains }

enum LogicalOperator { or, and }

// ignore: must_be_immutable
class SearchCriterio extends Equatable {
  final List<SearchCriterioItem> criterioItem = [];
  final List<OrderByItem> order = [];

  late int limit;

  SearchCriterio({this.limit = 20});

  Query getQuery(String collectionName) {
    QueryFilter filter = QueryFilter(collectionName);
    Query retorno = filter.getQueryWhere(this);

    return retorno;
  }

  Future<QuerySnapshot> getSnapshot(String collectionName) async {
    QueryFilter filter = QueryFilter(collectionName);
    QuerySnapshot retorno = await filter.getQuerySnapshot(this);

    return retorno;
  }

  void setCriterio(
    Object? field,
    Object? value, {
    LogicalOperator logicalOperator = LogicalOperator.and,
    CompareEnum compare = CompareEnum.isEqualTo,
  }) {
    _createItem(field, compare, value, logicalOperator);
  }

  void orderBy(String field, {bool desc = false}) {
    OrderByItem item = OrderByItem(field, desc);
    order.add(item);
  }

  void maxRows(int limit) {
    this.limit = limit;
  }

  void _createItem(
    Object? field,
    CompareEnum? compare,
    Object? value,
    LogicalOperator nextCondition,
  ) {
    if (field == null || field == "") {
      return;
    }

    // ignore: prefer_conditional_assignment
    if (compare == null) {
      compare = CompareEnum.isEqualTo;
    }

    if ((value == null || value.toString() == '') && compare != CompareEnum.isNotEqualTo) {
      return;
    }

    // ignore: prefer_conditional_assignment
    if (value == null) {
      value = '';
    }

    SearchCriterioItem item = SearchCriterioItem(
      field,
      compare,
      value,
      logicalOperator: nextCondition,
    );

    // confere se já não existe outro igual.
    bool existe = criterioItem.any((element) => element == item);

    if (existe) {
      // Remove o item atual
      criterioItem.removeWhere((element) => element.fieldName == field);
    }

    criterioItem.add(item);
  }

  SearchCriterio clone() {
    final clone = SearchCriterio();
    clone.limit = limit;

    clone.criterioItem.addAll(criterioItem.map((e) => e.clone()));

    clone.order.addAll(order.map((e) => e.clone()));

    return clone;
  }

  @override
  List<Object?> get props => [criterioItem, limit];
}

class OrderByItem extends Equatable {
  final String field;
  final bool desc;

  const OrderByItem(this.field, this.desc);

  OrderByItem clone() {
    final clone = OrderByItem(field, desc);
    return clone;
  }

  @override
  List<Object?> get props => [field, desc];
}

class SearchCriterioItem extends Equatable {
  final Object fieldName;
  final CompareEnum compare;
  final LogicalOperator logicalOperator;
  final Object value;

  SearchCriterioItem clone() {
    final clone = SearchCriterioItem(
      fieldName,
      compare,
      value,
      logicalOperator: logicalOperator,
    );
    return clone;
  }

  const SearchCriterioItem(
    this.fieldName,
    this.compare,
    this.value, {
    this.logicalOperator = LogicalOperator.and,
  });

  @override
  List<Object?> get props => [fieldName, compare, value];
}
