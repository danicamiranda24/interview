

part of 'transactions_dao.dart';

// ignore_for_file: type=lint
mixin _$TransactionsDaoMixin on DatabaseAccessor<Database> {
  $TransactionsTable get transactions => attachedDatabase.transactions;
}
