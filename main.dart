import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDb.instance.database;
  runApp(const LabApp());
}

class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'lab_sheet_8.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, content TEXT)');
      await db.execute('CREATE TABLE contacts(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, phone TEXT)');
      await db.execute('CREATE TABLE expenses(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, amount REAL)');
      await db.execute('CREATE TABLE tasks(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, completed INTEGER DEFAULT 0)');
      await db.execute('CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, email TEXT UNIQUE, password TEXT)');
      await db.execute('CREATE TABLE students(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, email TEXT, course TEXT)');
      await db.execute('CREATE TABLE products(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, quantity INTEGER, price REAL)');
      await db.execute('CREATE TABLE cart(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, quantity INTEGER, price REAL)');
    });
    return _db!;
  }

  Future<List<Map<String, Object?>>> all(String table, {String? search, String? column}) async {
    final db = await database;
    if (search != null && search.isNotEmpty && column != null) {
      return db.query(table, where: '$column LIKE ?', whereArgs: ['%$search%'], orderBy: 'id DESC');
    }
    return db.query(table, orderBy: 'id DESC');
  }

  Future<int> insert(String table, Map<String, Object?> values) async =>
      (await database).insert(table, values, conflictAlgorithm: ConflictAlgorithm.abort);

  Future<int> update(String table, int id, Map<String, Object?> values) async =>
      (await database).update(table, values, where: 'id = ?', whereArgs: [id]);

  Future<int> delete(String table, int id) async =>
      (await database).delete(table, where: 'id = ?', whereArgs: [id]);

  Future<double> expenseTotal() async {
    final rows = await (await database).rawQuery('SELECT SUM(amount) AS total FROM expenses');
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      await insert('users', {'name': name, 'email': email, 'password': password});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    final rows = await (await database).query('users',
        where: 'email = ? AND password = ?', whereArgs: [email, password]);
    return rows.isNotEmpty;
  }
}

class LabApp extends StatelessWidget {
  const LabApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Flutter SQLite Lab 8',
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    home: const HomePage(),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, List<FieldDef>)>[
      ('Notes App', 'notes', [FieldDef('Title', 'title'), FieldDef('Content', 'content', lines: 4)]),
      ('Contact Book', 'contacts', [FieldDef('Name', 'name'), FieldDef('Phone number', 'phone')]),
      ('Expense Tracker', 'expenses', [FieldDef('Expense title', 'title'), FieldDef('Amount', 'amount', numeric: true)]),
      ('To-Do List', 'tasks', [FieldDef('Task', 'title')]),
      ('Student Management', 'students', [FieldDef('Student name', 'name'), FieldDef('Email', 'email'), FieldDef('Course', 'course')]),
      ('Product Inventory', 'products', [FieldDef('Product name', 'name'), FieldDef('Quantity', 'quantity', numeric: true, integer: true), FieldDef('Price', 'price', numeric: true)]),
      ('Shopping Cart', 'cart', [FieldDef('Item name', 'name'), FieldDef('Quantity', 'quantity', numeric: true, integer: true), FieldDef('Price', 'price', numeric: true)]),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter SQLite Applications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('LAB SHEET – 8', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Choose an application to open. Data is saved locally using SQLite.'),
          const SizedBox(height: 12),
          ...items.map((item) => Card(child: ListTile(
            leading: const Icon(Icons.storage),
            title: Text(item.$1),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => RecordsPage(title: item.$1, table: item.$2, fields: item.$3))),
          ))),
          Card(child: ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Registration and Login'),
            subtitle: const Text('Create an account, then sign in'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage())),
          )),
        ],
      ),
    );
  }
}

class FieldDef {
  final String label;
  final String keyName;
  final bool numeric;
  final bool integer;
  final int lines;
  const FieldDef(this.label, this.keyName, {this.numeric = false, this.integer = false, this.lines = 1});
}

class RecordsPage extends StatefulWidget {
  final String title, table;
  final List<FieldDef> fields;
  const RecordsPage({super.key, required this.title, required this.table, required this.fields});
  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  List<Map<String, Object?>> rows = [];
  String query = '';
  double total = 0;
  bool get isTask => widget.table == 'tasks';
  bool get isExpense => widget.table == 'expenses';
  bool get isCart => widget.table == 'cart';
  bool get isContact => widget.table == 'contacts';
  bool get isNotes => widget.table == 'notes';
  String get searchColumn {
    if (widget.table == 'notes') return 'title';
    if (widget.table == 'contacts') return 'name';
    if (widget.table == 'students' || widget.table == 'products' || widget.table == 'cart') return 'name';
    return 'title';
  }

  @override
  void initState() { super.initState(); refresh(); }

  Future<void> refresh() async {
    final data = await AppDb.instance.all(widget.table,
      search: (isNotes || isContact || widget.table == 'students' || widget.table == 'products') ? query : null,
      column: searchColumn);
    final sum = isExpense ? await AppDb.instance.expenseTotal() : 0.0;
    if (mounted) setState(() { rows = data; total = sum; });
  }

  Future<void> openEditor([Map<String, Object?>? row]) async {
    final controllers = <String, TextEditingController>{};
    for (final f in widget.fields) {
      controllers[f.keyName] = TextEditingController(text: row?[f.keyName]?.toString() ?? '');
    }
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(row == null ? 'Add ${widget.title}' : 'Edit ${widget.title}'),
      content: Form(key: formKey, child: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.fields.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextFormField(
            controller: controllers[f.keyName],
            maxLines: f.lines,
            keyboardType: f.numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            decoration: InputDecoration(labelText: f.label, border: const OutlineInputBorder()),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter ${f.label.toLowerCase()}';
              if (f.numeric && double.tryParse(v.trim()) == null) return 'Enter a valid number';
              if (f.integer && int.tryParse(v.trim()) == null) return 'Enter a whole number';
              return null;
            },
          ),
        )).toList(),
      ))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          if (!formKey.currentState!.validate()) return;
          final values = <String, Object?>{};
          for (final f in widget.fields) {
            final value = controllers[f.keyName]!.text.trim();
            values[f.keyName] = f.numeric ? (f.integer ? int.parse(value) : double.parse(value)) : value;
          }
          try {
            if (row == null) {
              await AppDb.instance.insert(widget.table, values);
            } else {
              await AppDb.instance.update(widget.table, row['id'] as int, values);
            }
            if (dialogContext.mounted) Navigator.pop(dialogContext, true);
          } catch (_) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save. Check for duplicate or invalid data.')));
          }
        }, child: const Text('Save')),
      ],
    ));
    for (final c in controllers.values) { c.dispose(); }
    if (saved == true) refresh();
  }

  Future<void> remove(Map<String, Object?> row) async {
    if (isContact || widget.table == 'students' || widget.table == 'products' || isCart) {
      final yes = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
        title: const Text('Confirm delete'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ));
      if (yes != true) return;
    }
    await AppDb.instance.delete(widget.table, row['id'] as int);
    await refresh();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.title} deleted')));
  }

  Future<void> toggleTask(Map<String, Object?> row, bool? value) async {
    await AppDb.instance.update('tasks', row['id'] as int, {'completed': value == true ? 1 : 0});
    refresh();
  }

  String displayValue(Map<String, Object?> row) {
    if (isNotes) return '${row['title'] ?? ''}\n${row['content'] ?? ''}';
    if (isExpense) return '${row['title'] ?? ''}  •  ₹${row['amount'] ?? 0}';
    if (isTask) return row['title']?.toString() ?? '';
    if (widget.table == 'contacts') return '${row['name'] ?? ''}  •  ${row['phone'] ?? ''}';
    if (widget.table == 'students') return '${row['name'] ?? ''}  •  ${row['course'] ?? ''}\n${row['email'] ?? ''}';
    if (widget.table == 'products' || isCart) return '${row['name'] ?? ''}  •  Qty: ${row['quantity'] ?? 0}  •  ₹${row['price'] ?? 0}';
    return row.toString();
  }

  @override
  Widget build(BuildContext context) {
    final searchable = isNotes || isContact || widget.table == 'students' || widget.table == 'products';
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openEditor(), child: const Icon(Icons.add)),
      body: Column(children: [
        if (searchable) Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search...', border: OutlineInputBorder()),
            onChanged: (v) { query = v; refresh(); },
          ),
        ),
        if (isExpense) Padding(
          padding: const EdgeInsets.all(12),
          child: Card(child: ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Total expense (SUM)'),
            trailing: Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          )),
        ),
        if (isCart) FutureBuilder<double>(
          future: _cartTotal(), builder: (context, snapshot) => ListTile(
            title: const Text('Cart total'),
            trailing: Text('₹${(snapshot.data ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          )),
        Expanded(child: rows.isEmpty
          ? const Center(child: Text('No records yet. Tap + to add one.'))
          : ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              final tile = ListTile(
                leading: isTask ? Checkbox(value: row['completed'] == 1, onChanged: (v) => toggleTask(row, v)) : CircleAvatar(child: Text('${index + 1}')),
                title: Text(displayValue(row), style: isTask && row['completed'] == 1
                  ? const TextStyle(decoration: TextDecoration.lineThrough) : null),
                onTap: () => openEditor(row),
                trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => remove(row)),
              );
              if (isNotes) return Dismissible(
                key: ValueKey(row['id']), direction: DismissDirection.endToStart,
                background: Container(color: Colors.red, alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                onDismissed: (_) async {
                  await AppDb.instance.delete(widget.table, row['id'] as int);
                  refresh();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note deleted')));
                }, child: Card(child: tile));
              return Card(child: tile);
            },
          )),
      ]),
    );
  }

  Future<double> _cartTotal() async {
    final result = await (await AppDb.instance.database).rawQuery(
      'SELECT SUM(quantity * price) AS total FROM cart');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final name = TextEditingController(), email = TextEditingController(), password = TextEditingController();
  bool showRegister = true;
  String message = '';

  @override
  void dispose() { name.dispose(); email.dispose(); password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Registration and Login')),
    body: Padding(padding: const EdgeInsets.all(20), child: Column(
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Register')),
            ButtonSegment(value: false, label: Text('Login')),
          ],
          selected: {showRegister},
          onSelectionChanged: (v) => setState(() { showRegister = v.first; message = ''; }),
        ),
        const SizedBox(height: 18),
        if (showRegister) TextField(controller: name, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
        if (showRegister) const SizedBox(height: 12),
        TextField(controller: email, keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: password, obscureText: true,
          decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        FilledButton(onPressed: () async {
          final validEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email.text.trim());
          if ((showRegister && name.text.trim().isEmpty) || !validEmail || password.text.length < 6) {
            setState(() => message = 'Enter all required details, a valid email and a password of at least 6 characters.');
            return;
          }
          if (showRegister) {
            final ok = await AppDb.instance.register(name.text.trim(), email.text.trim(), password.text);
            setState(() => message = ok ? 'Registration successful. You can now log in.' : 'This email may already be registered.');
          } else {
            final ok = await AppDb.instance.login(email.text.trim(), password.text);
            setState(() => message = ok ? 'Login successful! Welcome to the Home screen.' : 'Invalid email or password.');
          }
        }, child: Text(showRegister ? 'Create account' : 'Login')),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
      ],
    )),
  );
}
