import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/add_new_task.dart';
import 'package:frontend/utils.dart';
import 'package:frontend/widgets/date_selector.dart';
import 'package:frontend/widgets/task_card.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddNewTask(),
                ),
              );
            },
            icon: const Icon(
              Icons.add,
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            const DateSelector(),
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("tasks")
                  .where(
                    "uid",
                    isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                print("StreamBuilder rebuilt with ${snapshot.data?.docs.length ?? 0} items");
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }
                if (!snapshot.hasData) {
                  return const Text("Uh Oh\nNo Data :(");
                }
                return Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      return Dismissible(
                        key: ValueKey(index),
                        onDismissed: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            try {
                              await FirebaseFirestore.instance
                                  .collection("tasks")
                                  .doc(snapshot.data!.docs[index].id)
                                  .delete();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Failed to delete task: $e')),
                              );
                            }
                          }
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: TaskCard(
                                color: hexToColor(
                                  snapshot.data!.docs[index].data()['color'],
                                ),
                                headerText:
                                    snapshot.data!.docs[index].data()['title'],
                                descriptionText: snapshot.data!.docs[index]
                                    .data()['description'],
                                scheduledDate: snapshot.data!.docs[index]
                                    .data()['date']
                                    .toString(),
                              ),
                            ),
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: strengthenColor(
                                  hexToColor(
                                    snapshot.data!.docs[index].data()['color'],
                                  ),
                                  0.69,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text(
                                '10:00AM',
                                style: TextStyle(
                                  fontSize: 17,
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
