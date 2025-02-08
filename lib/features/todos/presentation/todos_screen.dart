import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/todo_model.dart';
import '../data/todo_provider.dart';
import 'add_todo_bottom_sheet.dart';
import 'todo_list_widget.dart';

class TodosScreen extends ConsumerStatefulWidget {
  @override
  _TodosScreenState createState() => _TodosScreenState();
}

class _TodosScreenState extends ConsumerState<TodosScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String currentUserEmail;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Get current user email from Supabase
    currentUserEmail = Supabase.instance.client.auth.currentUser?.email ?? '';
    
    // Load todos when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(todosProvider.notifier).loadTodos(currentUserEmail);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Todos',style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,  // Set tab text color to white
          unselectedLabelColor: Colors.white70,  // Slightly faded white for unselected tabs
          tabs: [
            Tab(text: 'Food'),
            Tab(text: 'Places'),
            Tab(text: 'Standard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TodoListWidget(category: TodoCategory.Food),
          TodoListWidget(category: TodoCategory.Places),
          TodoListWidget(category: TodoCategory.Standard),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoBottomSheet(context),
        backgroundColor: Color(0xFF862C24),
       
        child: Icon(Icons.add,color: Colors.white,),
      ),
    );
  }

  void _showAddTodoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => AddTodoBottomSheet(userEmail: currentUserEmail),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}