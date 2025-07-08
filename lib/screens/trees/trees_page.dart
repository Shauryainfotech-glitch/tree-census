import 'package:flutter/material.dart';

class TreesPage extends StatelessWidget {
  const TreesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.park, size: 64, color: Colors.green[700]),
            const SizedBox(height: 24),
            Text(
              'Trees',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'This page will display a list of all trees, their locations, and details. You can add, edit, or view tree information here.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  // Tablet/Desktop: show a wide placeholder table
                  return DataTable(
                    columns: const [
                      DataColumn(label: Text('Tree ID')),
                      DataColumn(label: Text('Species')),
                      DataColumn(label: Text('Location')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: List.generate(3, (index) => DataRow(cells: [
                      DataCell(Text('TREE00${index + 1}')),
                      DataCell(Text('Neem')),
                      DataCell(Text('Ward ${index + 1}')),
                      DataCell(Text('Healthy')),
                    ])),
                  );
                } else {
                  // Mobile: show a simple list
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.park),
                        title: Text('Tree TREE00${index + 1}'),
                        subtitle: Text('Species: Neem\nStatus: Healthy'),
                        trailing: Text('Ward ${index + 1}'),
                      ),
                    )),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
