import 'package:flutter/material.dart';
import '../models/ingredient.dart';

class CompareScreen extends StatelessWidget {
  final List<Ingredient> items;
  const CompareScreen({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Scaffold(body: Center(child: Text('Karşılaştırmak için seçili malzeme yok')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Karşılaştırma')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Alan')),
            ...items.map((e)=> DataColumn(label: SizedBox(width:140, child: Text(e.core.primaryName, maxLines:2, overflow: TextOverflow.ellipsis)))),
          ],
          rows: [
            _row('Risk', items.map((e)=> '${e.risk.riskLevel} (${e.risk.riskScore})').toList()),
            _row('Kategori', items.map((e)=> e.core.category).toList()),
            _row('Alt Kategori', items.map((e)=> e.core.subcategory).toList()),
            _row('Roller', items.map((e)=> e.usage.commonRoles.join(', ')).toList()),
            _row('Sağlık Flag', items.map((e)=> e.health.healthFlags.join(', ')).toList()),
            _row('Risk Faktörleri', items.map((e)=> e.risk.riskFactors.join(', ')).toList()),
          ],
        ),
      ),
    );
  }

  DataRow _row(String label, List<String> vals) {
    return DataRow(cells: [
      DataCell(Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
      ...vals.map((v)=> DataCell(SizedBox(width:140, child: Text(v, maxLines:4, overflow: TextOverflow.ellipsis)))),
    ]);
  }
}