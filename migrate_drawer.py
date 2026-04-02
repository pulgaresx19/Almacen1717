import sys

def process():
    with open(r'c:\App New\lib\screens\awb_module.dart', 'r', encoding='utf-8') as f:
        awb_text = f.read()

    start_idx = awb_text.find('  void _showAwbDrawer(')
    if start_idx == -1: return 'showAwbDrawer not found'
    end_idx = awb_text.find('  Widget _buildStatusBadge(', start_idx)
    if end_idx == -1: return 'end_idx not found'

    drawer_func = awb_text[start_idx:end_idx]

    with open(r'c:\App New\lib\screens\add_deliver_screen.dart', 'r', encoding='utf-8') as f:
        add_text = f.read()

    # Insert Info column
    col_target = "DataColumn(label: Text('Status')),"
    col_repl = "DataColumn(label: Text('Status')),\n                      const DataColumn(label: Text('')),"
    add_text = add_text.replace(col_target, col_repl)

    # Insert Info cell
    cell_target = "DataCell(_buildStatusBadge(status)),\n                        ],"
    cell_repl = "DataCell(_buildStatusBadge(status)),\n                          DataCell(\n                            IconButton(\n                              icon: Icon(Icons.info_outline_rounded, color: dark ? const Color(0xFF818cf8) : const Color(0xFF6366f1), size: 18),\n                              onPressed: () => _showAwbDrawer(context, awb, dark, receivedPieces, expectedPieces, status),\n                              tooltip: 'Ver Info',\n                            ),\n                          ),\n                        ],"
    add_text = add_text.replace(cell_target, cell_repl)

    # Insert drawer func
    insert_target = '  Widget _buildAwbSelector(bool dark) {'
    add_text = add_text.replace(insert_target, drawer_func + '\n' + insert_target)

    with open(r'c:\App New\lib\screens\add_deliver_screen.dart', 'w', encoding='utf-8') as f:
        f.write(add_text)

    print('OK')

process()
