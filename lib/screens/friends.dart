import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _sendFriendRequest(String friendUid) async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null || friendUid == currentUserUid) return;

    final friendsRef = FirebaseFirestore.instance.collection('friends');
    final existingRequest = await friendsRef
        .where('requesterId', isEqualTo: currentUserUid)
        .where('receiverId', isEqualTo: friendUid)
        .get();

    if (existingRequest.docs.isEmpty) {
      await friendsRef.add({
        'requesterId': currentUserUid,
        'receiverId': friendUid,
        'status': 'pending',
        'timestamp': Timestamp.now(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Friend request sent!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request already sent.")));
    }
  }

  Future<void> _searchUsers(String username) async {
    setState(() {
      _isLoading = true;
      _searchResults.clear();
    });

    final snapshot = await FirebaseFirestore.instance
        .collection('JourneyMate')
        .where('username', isEqualTo: username)
        .get();

    setState(() {
      _isLoading = false;
      _searchResults = snapshot.docs.map((doc) => {
        'uid': doc.id,
        'username': doc['username'],
      }).toList();
    });
  }

  Future<String> _getUsernameByUid(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('JourneyMate').doc(uid).get();
    if (doc.exists && doc.data()!.containsKey('username')) {
      return doc['username'] ?? 'Unknown User';
    }
    return 'Unknown User';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Friends"),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "FRIENDS"),
              Tab(text: "PENDING"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: "Search Friends by Username",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () async {
                          await _searchUsers(_searchController.text.trim());
                        },
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
                if (!_isLoading && _searchResults.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(user['username']),
                          trailing: ElevatedButton(
                            onPressed: () => _sendFriendRequest(user['uid']),
                            child: const Text("Add Friend"),
                          ),
                        );
                      },
                    ),
                  ),
                if (!_isLoading && _searchResults.isEmpty)
                  const Expanded(child: Center(child: Text("No users found."))),
              ],
            ),
            _buildPendingTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTab() {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) {
      return const Center(child: Text("Not logged in"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friends')
          .where('receiverId', isEqualTo: currentUserUid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No pending requests."));
        }
        final requests = snapshot.data!.docs;
        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index].data() as Map<String, dynamic>;
            return FutureBuilder<String>(
              future: _getUsernameByUid(request['requesterId']),
              builder: (context, usernameSnapshot) {
                if (usernameSnapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    leading: CircleAvatar(child: Icon(Icons.person)),
                    title: Text("Loading username..."),
                  );
                }
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text("Request from: ${usernameSnapshot.data}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('friends')
                              .doc(requests[index].id)
                              .update({'status': 'accepted'});
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Friend request accepted.")));
                        },
                        child: const Text("Accept", style: TextStyle(color: Colors.green)),
                      ),
                      TextButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('friends')
                              .doc(requests[index].id)
                              .delete();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Friend request rejected.")));
                        },
                        child: const Text("Reject", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
