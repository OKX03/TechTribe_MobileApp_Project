import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../memory/memory_details_page.dart';
import '../../repository/report_repository.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.filter_alt),
                label: Text(widget.filterRange == null
                    ? 'Filter by Date'
                    : '${DateFormat('yyyy-MM-dd').format(widget.filterRange!.start)} - ${DateFormat('yyyy-MM-dd').format(widget.filterRange!.end)}'),
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
                  final data = docs[index].data() as Map<String, dynamic>;
                  final reason = data['reason'] ?? '';
                  final reportedBy = data['reportedBy'] ?? '';
                  final memoryId = data['memoryId'] ?? '';
                  final timestamp = (data['timestamp'] as Timestamp).toDate();
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      onTap: () async {
                        final memoryData = await _repo.getMemoryById(memoryId);
                        if (memoryData != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MemoryDetailPage(
                                memoryId: memoryId,
                                memoryData: memoryData,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Memory not found')),
                          );
                        }
                      },
                      title: Text('Reason: $reason'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reported by: $reportedBy'),
                          Text('Memory ID: $memoryId'),
                          Text('Time: ${DateFormat('yyyy-MM-dd HH:mm').format(timestamp)}'),
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