import 'package:balance/core/database/dao/groups_dao.dart';
import 'package:balance/core/database/dao/transactions_dao.dart';
import 'package:balance/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GroupPage extends StatefulWidget {
  final String groupId;
  const GroupPage(this.groupId, {super.key});

  @override
  State<StatefulWidget> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  late final GroupsDao _groupsDao;
  late final TransactionsDao _transactionsDao;
  @override
  void initState() {
    super.initState();
    _groupsDao = getIt.get<GroupsDao>();
    _transactionsDao = getIt.get<TransactionsDao>();
  }

  final _incomeController = TextEditingController();
  final _expenseController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Group details"),
        ),
        body: StreamBuilder(
          stream: _groupsDao.watchGroup(widget.groupId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text("Loading...");
            }
            return Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(snapshot.data?.name ?? ""),
                Text(snapshot.data?.balance.toString() ?? ""),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _incomeController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[0-9]"))
                      ],
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                        suffixText: "\$",
                      ),
                    ),
                  ),
                  TextButton(
                      onPressed: () {
                        final amount = int.parse(_incomeController.text);
                        final name = snapshot.data?.name;
                        final balance = snapshot.data?.balance ?? 0;
                        _groupsDao.adjustBalance(
                            balance + amount, widget.groupId);
                        _transactionsDao.insert(amount, widget.groupId).then(
                              (value) => ScaffoldMessenger.of(context)
                                  .showMaterialBanner(
                                MaterialBanner(
                                  content: Text(
                                      'New transaction inserted : $amount to $name'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            ScaffoldMessenger.of(context)
                                                .hideCurrentMaterialBanner(),
                                        child: const Text('Close')),
                                  ],
                                ),
                              ),
                            );
                        _incomeController.text = "";
                      },
                      child: const Text("Add income")),
                ]),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expenseController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[0-9]"))
                      ],
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                        suffixText: "\$",
                      ),
                    ),
                  ),
                  TextButton(
                      onPressed: () {
                        final amount = int.parse(_expenseController.text);
                        final balance = snapshot.data?.balance ?? 0;
                        _groupsDao.adjustBalance(
                            balance - amount, widget.groupId);
                        _transactionsDao.insert(-amount, widget.groupId);
                        _expenseController.text = "";
                      },
                      child: const Text("Add expense")),
                ]),
                getTransactions(snapshot.data?.balance),
              ],
            );
          },
        ),
      );

  Widget getTransactions(final balance) {
    return StreamBuilder(
      stream:
          _transactionsDao.watchCurrentUserTransactionHistory(widget.groupId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text("Loading...");
        }
        return Expanded(
          child: ListView.builder(
              itemCount: snapshot.requireData.length,
              itemBuilder: (context, index) => ListTile(
                    title: Text(snapshot.data![index].createdAt.toString()),
                    subtitle: Text(snapshot.data![index].amount.toString()),
                    onTap: () {
                      _displayAmount(context,
                          snapshot.data![index].amount.toString(), balance,snapshot.data![index].id);
                    },
                  )),
        );
      },
    );
  }

  void _displayAmount(BuildContext context, final oldAmount, final balance,final id) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Edit Amount"),
            content: TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: oldAmount),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (_amountController.text.isNotEmpty) {
                    setState(() {
                      final amount = int.parse(_amountController.text);
                      final oldAmountValue = int.parse(oldAmount);
                         _groupsDao.adjustBalance(
                            balance + (amount - oldAmountValue) , widget.groupId);
                      _transactionsDao.updateAmount(amount, id, widget.groupId);
                    });
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        });
  }
}
