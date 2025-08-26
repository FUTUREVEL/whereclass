import 'package:flutter/material.dart';

class SearchHistoryButton extends StatelessWidget {
  const SearchHistoryButton(
      {super.key, required this.searchTerm, this.onTap, this.onDelete});

  final String searchTerm;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InputChip(
        label: Text(searchTerm, overflow: TextOverflow.ellipsis),
        onPressed: onTap,
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: onDelete,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        side: BorderSide(color: Colors.grey.shade300),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      ),
    );
  }
}
