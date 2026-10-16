import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

// ==================== APP ====================

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const ExpenseHomePage(),
    );
  }
}

// ==================== HOME PAGE ====================

class ExpenseHomePage extends StatefulWidget {
  const ExpenseHomePage({super.key});

  @override
  State<ExpenseHomePage> createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  // Expenses list
  final List<Map<String, String>> expenses = [];

  // Text controllers
  final TextEditingController titleController =
      TextEditingController();

  final TextEditingController amountController =
      TextEditingController();

  // Category
  String selectedCategory = 'Other';

  final List<String> categories = [
    'Food',
    'Travel',
    'Shopping',
    'Education',
    'Other',
  ];

  // ==================== INIT ====================

 @override
void initState() {
  super.initState();
  loadExpenses();
}
  // ==================== DISPOSE ====================

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  // ==================== TOTAL ====================

  double calculateTotal() {
    double total = 0;

    for (var expense in expenses) {
      total += double.tryParse(
            expense['amount'] ?? '0',
          ) ??
          0;
    }

    return total;
  }

  // ==================== SAVE EXPENSES ====================

  Future<void> saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'expenses',
      jsonEncode(expenses),
    );
  }

  // ==================== LOAD EXPENSES ====================

  Future<void> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();

    final savedExpenses = prefs.getString('expenses');

    if (savedExpenses == null) {
      return;
    }

    try {
      final List<dynamic> data = jsonDecode(savedExpenses);

      if (!mounted) return;

      setState(() {
        expenses.clear();

        for (var expense in data) {
          expenses.add({
            'title': expense['title']?.toString() ?? '',
            'amount': expense['amount']?.toString() ?? '0',
            'category':
                expense['category']?.toString() ?? 'Other',
            'date': expense['date']?.toString() ?? '',
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    }
  }

  // ==================== ADD EXPENSE ====================

  void addExpense() {
    if (titleController.text.trim().isEmpty ||
        amountController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      expenses.add({
        'title': titleController.text.trim(),
        'amount': amountController.text.trim(),
        'category': selectedCategory,
        'date': DateTime.now().toString().split(' ')[0],
      });
    });

    saveExpenses();

    titleController.clear();
    amountController.clear();

    Navigator.pop(context);
  }

  // ==================== CATEGORY ICON ====================

  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;

      case 'Travel':
        return Icons.directions_bus;

      case 'Shopping':
        return Icons.shopping_bag;

      case 'Education':
        return Icons.school;

      default:
        return Icons.money;
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
      ),

      // ==================== BODY ====================

      body: Column(
        children: [
          // Total Expense Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Expense',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '₹ ${calculateTotal()}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Expense List
          Expanded(
            child: expenses.isEmpty
                ? const Center(
                    child: Text(
                      'No expenses yet',
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];

                      return ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            getCategoryIcon(
                              expense['category'] ?? 'Other',
                            ),
                          ),
                        ),

                        title: Text(
                          expense['title'] ?? '',
                        ),

                        subtitle: Text(
                          '₹ ${expense['amount']} • '
                          '${expense['category']} • '
                          '${expense['date']}',
                        ),

                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                          ),

                          onPressed: () {
                            setState(() {
                              expenses.removeAt(index);
                            });

                            saveExpenses();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // ==================== ADD BUTTON ====================

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom:
                      MediaQuery.of(context)
                          .viewInsets
                          .bottom +
                      20,
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Add Expense',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Expense Name
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Expense Name',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Amount
                    TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Category
                    DropdownButtonFormField<String>(
                      value: selectedCategory,

                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),

                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),

                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          selectedCategory = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // Add Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: addExpense,
                        child: const Text(
                          'Add Expense',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },

        child: const Icon(Icons.add),
      ),
    );
  }
}