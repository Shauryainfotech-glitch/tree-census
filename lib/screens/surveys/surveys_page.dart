import 'package:flutter/material.dart';

class SurveysPage extends StatelessWidget {
  const SurveysPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.blue[700]),
            const SizedBox(height: 24),
            Text(
              'Surveys',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'This page will display all survey activities, assignments, and results. You can manage and review surveys here.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  // Tablet/Desktop: show a wide placeholder table
                  return DataTable(
                    columns: const [
                      DataColumn(label: Text('Survey ID')),
                      DataColumn(label: Text('Surveyor')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Date')),
                    ],
                    rows: List.generate(3, (index) => DataRow(cells: [
                      DataCell(Text('SURV00${index + 1}')),
                      DataCell(Text('Surveyor ${index + 1}')),
                      DataCell(Text('Completed')),
                      DataCell(Text('2025-07-0${index + 1}')),
                    ])),
                  );
                } else {
                  // Mobile: show a simple list
                  return Column(
                    children: List.generate(3, (index) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.assignment),
                        title: Text('Survey SURV00${index + 1}'),
                        subtitle: Text('Surveyor ${index + 1}\nStatus: Completed'),
                        trailing: Text('2025-07-0${index + 1}'),
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
