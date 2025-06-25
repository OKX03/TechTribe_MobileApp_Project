import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../memory/memory_details_page.dart';
import '../../repository/report_repository.dart';
import '../../models/report.dart';

class ReportedMemoriesTab extends StatefulWidget {
  final DateTimeRange? filterRange;
  final Function(DateTimeRange?) onFilterChanged;

  const ReportedMemoriesTab({
    super.key,
    required this.filterRange,
    required this.onFilterChanged,
  });

  @override
  State<ReportedMemoriesTab> createState() => _ReportedMemoriesTabState();
}

class _ReportedMemoriesTabState extends State<ReportedMemoriesTab> {
  final ReportRepository _repo = ReportRepository();

  void _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: widget.filterRange,
    );
    if (picked != null) {
      widget.onFilterChanged(picked);
    }
  }

  Future<void> _updateReportStatus(
    String reportId,
    ReportStatus newStatus,
  ) async {
    try {
      await _repo.updateReportStatus(reportId, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status updated to ${newStatus.toString().split('.').last}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showDeleteConfirmationDialog(String reason) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Reported Memory'),
              content: Text(
                'Are you sure you want to delete this memory?\n\nReason for report: $reason\n\n'
                'This action will:\n'
                '• Delete the memory permanently\n'
                '• Remove all associated comments\n'
                '• Delete the report\n\n'
                'This action cannot be undone.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _handleDelete(
    String reportId,
    String memoryId,
    String reason,
  ) async {
    final shouldDelete = await _showDeleteConfirmationDialog(reason);
    if (!shouldDelete || !mounted) return;

    try {
      await _repo.deleteMemoryAndReport(memoryId: memoryId, reportId: reportId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memory and report deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // If the memory was already deleted, try to delete just the report
      try {
        await _repo.deleteReport(reportId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatusBadge(ReportStatus status) {
    Color color;
    switch (status) {
      case ReportStatus.pending:
        color = Colors.orange;
        break;
      case ReportStatus.inReview:
        color = Colors.blue;
        break;
      case ReportStatus.resolved:
        color = Colors.green;
        break;
      case ReportStatus.dismissed:
        color = Colors.grey;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toString().split('.').last,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.filter_alt),
                  label: Text(
                    widget.filterRange == null
                        ? 'Filter by Date'
                        : '${DateFormat('yyyy-MM-dd').format(widget.filterRange!.start)} - ${DateFormat('yyyy-MM-dd').format(widget.filterRange!.end)}',
                  ),
                ),
              ),
              if (widget.filterRange != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => widget.onFilterChanged(null),
                  tooltip: 'Clear filter',
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _repo.getReportsStream(filterRange: widget.filterRange),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text('No reports found.'));
              }
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final reason = data['reason'] ?? '';
                  final reportedBy = data['reportedBy'] ?? '';
                  final memoryId = data['memoryId'] ?? '';
                  final timestamp = (data['timestamp'] as Timestamp).toDate();
                  final status = Report.statusFromString(data['status'] ?? '');

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      onTap: () async {
                        final memoryData = await _repo.getMemoryById(memoryId);
                        if (memoryData != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => MemoryDetailPage(
                                    memoryId: memoryId,
                                    memoryData: memoryData,
                                  ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Memory not found')),
                          );
                        }
                      },
                      title: Row(
                        children: [
                          Expanded(child: Text('Reason: $reason')),
                          _buildStatusBadge(status),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reported by: $reportedBy'),
                          Text('Memory ID: $memoryId'),
                          Text(
                            'Time: ${DateFormat('yyyy-MM-dd HH:mm').format(timestamp)}',
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed:
                                () => _handleDelete(doc.id, memoryId, reason),
                            tooltip: 'Delete Memory',
                          ),
                          PopupMenuButton<ReportStatus>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (ReportStatus status) {
                              _updateReportStatus(doc.id, status);
                            },
                            itemBuilder: (BuildContext context) {
                              return ReportStatus.values
                                  .where((s) => s != status)
                                  .map((ReportStatus status) {
                                    return PopupMenuItem<ReportStatus>(
                                      value: status,
                                      child: Text(
                                        status.toString().split('.').last,
                                      ),
                                    );
                                  })
                                  .toList();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
