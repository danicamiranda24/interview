import 'package:balance/core/database/database.dart';
import 'package:balance/core/database/tables/transactions.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

part 'transactions_dao.g.dart';

@lazySingleton
@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<Database>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Future insert(int amount, String groupId) {
    return into(transactions).insert(TransactionsCompanion.insert(
        id: const Uuid().v1(),
        createdAt: DateTime.now(),
        amount: Value(amount),
        groupId: groupId));
  }

  Future updateAmount(int amount, String id,String groupId) async {
    final companion = TransactionsCompanion(amount: Value(amount));

    return (update(transactions)..where((tbl) => tbl.id.equals(id)))
        .write(companion);
  }

  Stream<List<Transaction>> watchCurrentUserTransactionHistory(
      String currentUserID) {
    return (select(transactions)..where((tbl) => tbl.groupId.equals(currentUserID)))
        .watch();
  }
}
