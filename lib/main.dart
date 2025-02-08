import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Todo App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TodoList(),
    );
  }
}

class Todo {
  String task;
  String description;
  bool isDone;

  Todo({
    required this.task,
    this.description = "",
    this.isDone = false,
  });

  // Convert a Todo object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'task': task,
      'description': description,
      'isDone': isDone,
    };
  }

  // Convert a Firestore document to a Todo object
  factory Todo.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Todo(
      task: data['task'] ?? '',
      description: data['description'] ?? '',
      isDone: data['isDone'] ?? false,
    );
  }
}

class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  _TodoListState createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  final TextEditingController _todoController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Firebase Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Firestore collection
  late CollectionReference _todosCollection;

  @override
  void initState() {
    super.initState();
    _todosCollection = _firestore.collection('todos');
  }

  // Add Todo to Firestore
  void _addTodo() async {
    if (_todoController.text.isEmpty) return;

    final newTodo = Todo(
      task: _todoController.text,
      description: _descriptionController.text,
    );

    await _todosCollection.add(newTodo.toMap()); // Add to Firestore

    _todoController.clear();
    _descriptionController.clear();
  }

  // Toggle Todo status in Firestore
  void _toggleTodoStatus(String docId, bool currentStatus) async {
    await _todosCollection.doc(docId).update({'isDone': !currentStatus});
  }

  // Delete Todo from Firestore
  void _deleteTodo(String docId) async {
    await _todosCollection.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
        actions: [IconButton(onPressed: _addTodo, icon: Icon(Icons.add))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _todoController,
              decoration: InputDecoration(labelText: 'Enter Task'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Enter Description'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _todosCollection.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final todos = snapshot.data!.docs.map((doc) {
                    return Todo.fromFirestore(doc);
                  }).toList();

                  return ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      final todo = todos[index];
                      return ListTile(
                        title: Text(
                          todo.task,
                          style: TextStyle(
                            decoration: todo.isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        leading: Checkbox(
                          value: todo.isDone,
                          onChanged: (_) => _toggleTodoStatus(
                              snapshot.data!.docs[index].id, todo.isDone),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            todo.description,
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _deleteTodo(snapshot.data!.docs[index].id);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
