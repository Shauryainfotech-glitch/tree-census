import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/request_provider.dart';
import '../../utils/theme.dart';
import '../../models/tree_request.dart';

class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RequestProvider>(
      builder: (context, requestProvider, child) {
        if (requestProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (requestProvider.errorMessage != null) {
          return Center(child: Text(requestProvider.errorMessage!));
        }
        final requests = requestProvider.allRequests;
        if (requests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.orange[700]),
                  const SizedBox(height: 24),
                  Text(
                    'No Requests',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const Text('No requests found. All your requests will appear here.'),
                ],
              ),
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              // Tablet/Desktop: show a table
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Request ID')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Date')),
                  ],
                  rows: requests
                      .map(
                        (req) => DataRow(
                          cells: [
                            DataCell(Text(req.id)),
                            DataCell(Text(req.requestType.displayName)),
                            DataCell(_statusChip(req.status)),
                            DataCell(Text(_formatDate(req.submissionDate))),
                          ],
                        ),
                      )
                      .toList(),
                ),
              );
            } else {
              // Mobile: show a list
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(Icons.request_page, color: AppTheme.accentBlue),
                      title: Text(req.requestType.displayName),
                      subtitle: Text(
                        'ID: ${req.id}\nStatus: ${req.status.displayName}\nDate: ${_formatDate(req.submissionDate)}',
                      ),
                      isThreeLine: true,
                      trailing: _statusChip(req.status),
                      onTap: () {
                        // Optionally show details or navigate
                      },
                    ),
                  );
                },
              );
            }
          },
        );
      },
    );
  }

  Widget _statusChip(RequestStatus status) {
    Color color;
    switch (status) {
      case RequestStatus.pending:
        color = AppTheme.warningOrange;
        break;
      case RequestStatus.approved:
        color = AppTheme.successGreen;
        break;
      case RequestStatus.rejected:
        color = AppTheme.errorRed;
        break;
      default:
        color = AppTheme.infoBlue;
    }
    return Chip(
      label: Text(status.displayName),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
