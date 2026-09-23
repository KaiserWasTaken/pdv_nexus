import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  
  String _selectedCategory = 'Empresa';
  String _selectedPaymentMethod = 'Efectivo';

  final List<String> _categories = ['Empresa', 'Personal'];
  final List<String> _paymentMethods = ['Efectivo', 'Crédito', 'Débito'];

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitExpense() async {
    if (_formKey.currentState!.validate()) {
      final db = context.read<AppDatabase>();
      final amount = double.tryParse(_amountController.text) ?? 0;

      try {
        await db.expenseDao.insertExpense(
          ExpensesCompanion.insert(
            description: _descriptionController.text,
            amount: amount,
            category: _selectedCategory,
            paymentMethod: _selectedPaymentMethod,
            date: drift.Value(DateTime.now()),
          ),
        );

        _descriptionController.clear();
        _amountController.clear();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gasto registrado correctamente')),
          );
          // Ocultar teclado
          FocusScope.of(context).unfocus();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al registrar: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    const nexusYellow = Color(0xFFFFDE00);
    const nexusBlue = Color(0xFF00187A);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "CONTROL DE GASTOS",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            
            // Área de Formulario (Scrollable si es necesario)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color: nexusBlue.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: nexusYellow, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _descriptionController,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                        labelText: 'Descripción del gasto',
                                        labelStyle: TextStyle(color: Colors.white70),
                                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                                      ),
                                      validator: (value) => value!.isEmpty ? 'Requerido' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _amountController,
                                      style: const TextStyle(color: Colors.white),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Monto (\$)',
                                        labelStyle: TextStyle(color: Colors.white70),
                                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                                      ),
                                      validator: (value) => value!.isEmpty ? 'Requerido' : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  // Si el espacio es muy estrecho (ej. teclado abierto), apilamos los botones
                                  bool useStack = constraints.maxWidth < 500;
                                  
                                  List<Widget> formItems = [
                                    Expanded(
                                      flex: useStack ? 0 : 1,
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedCategory,
                                        dropdownColor: const Color(0xFF000F4D),
                                        style: const TextStyle(color: Colors.white),
                                        decoration: const InputDecoration(
                                          labelText: 'Categoría',
                                          labelStyle: TextStyle(color: Colors.white70),
                                        ),
                                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                        onChanged: (val) => setState(() => _selectedCategory = val!),
                                      ),
                                    ),
                                    SizedBox(width: useStack ? 0 : 16, height: useStack ? 16 : 0),
                                    Expanded(
                                      flex: useStack ? 0 : 1,
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedPaymentMethod,
                                        dropdownColor: const Color(0xFF000F4D),
                                        style: const TextStyle(color: Colors.white),
                                        decoration: const InputDecoration(
                                          labelText: 'Método de Pago',
                                          labelStyle: TextStyle(color: Colors.white70),
                                        ),
                                        items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                                        onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                                      ),
                                    ),
                                    SizedBox(width: useStack ? 0 : 16, height: useStack ? 24 : 0),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: nexusYellow,
                                        foregroundColor: nexusBlue,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: _submitExpense,
                                      child: const Text("REGISTRAR GASTO", style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ];

                                  return useStack 
                                    ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: formItems)
                                    : Row(children: formItems);
                                }
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    const Text(
                      "GASTOS ACTIVOS (DÍA ACTUAL)",
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    
                    // Lista de Gastos usando shrinkWrap para que viva dentro del SingleChildScrollView
                    StreamBuilder<List<Expense>>(
                      stream: db.expenseDao.watchActiveExpenses(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red));
                        }
                        if (!snapshot.hasData) {
                          return const Center(child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ));
                        }
                        
                        final expenses = snapshot.data!;
                        if (expenses.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text("No hay gastos registrados hoy", style: TextStyle(color: Colors.white24)),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: expenses.length,
                          itemBuilder: (context, index) {
                            final exp = expenses[index];
                            return Card(
                              color: Colors.white.withOpacity(0.05),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: exp.category == 'Empresa' ? Colors.blue : Colors.purple,
                                  child: Icon(
                                    exp.category == 'Empresa' ? Icons.business : Icons.person,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text(exp.description, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                subtitle: Text("${exp.category} • ${exp.paymentMethod}", style: const TextStyle(color: Colors.white60)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "-\$${exp.amount.toStringAsFixed(2)}",
                                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.white24),
                                      onPressed: () => db.expenseDao.deleteExpense(exp.id),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
