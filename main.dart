import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// Setelah menjalankan `flutterfire configure`, buka komentar berikut:
// import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ganti inisialisasi ini dengan:
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Firebase.initializeApp();
  runApp(const RT08App());
}

class RT08App extends StatelessWidget {
  const RT08App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'RT 08',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff174b78)),
      useMaterial3: true),
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return snap.data == null ? const LoginPage() : const HomePage();
    },
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(), password = TextEditingController();
  bool register = false, busy = false;
  String error = '';
  Future<void> submit() async {
    setState(() { busy = true; error = ''; });
    try {
      if (register) {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(), password: password.text);
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'email': email.text.trim(), 'role': 'warga', 'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(), password: password.text);
      }
    } on FirebaseAuthException catch (e) {
      error = e.message ?? e.code;
    } catch (e) { error = e.toString(); }
    if (mounted) setState(() => busy = false);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.apartment, size: 68, color: Color(0xff174b78)),
          const Text('RT 08', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          const Text('Sistem Informasi Warga', textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Text(register ? 'Buat akun warga' : 'Masuk aplikasi',
            style: Theme.of(context).textTheme.titleLarge),
          TextField(controller: email, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
          TextField(controller: password, obscureText: true,
            decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock))),
          if (error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8),
            child: Text(error, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 16),
          FilledButton(onPressed: busy ? null : submit,
            child: Text(busy ? 'Memproses...' : (register ? 'Daftar' : 'Masuk'))),
          TextButton(onPressed: () => setState(() { register = !register; error = ''; }),
            child: Text(register ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar')),
        ],
      )))),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int tab = 0;
  final pages = const [DashboardTab(), ReportsTab(), AnnouncementsTab(), AdminMenuTab()];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('RT 08'), actions: [
      IconButton(tooltip: 'Keluar', onPressed: () => FirebaseAuth.instance.signOut(),
        icon: const Icon(Icons.logout))
    ]),
    body: pages[tab],
    bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
        NavigationDestination(icon: Icon(Icons.report_outlined), label: 'Laporan'),
        NavigationDestination(icon: Icon(Icons.campaign_outlined), label: 'Info RT'),
        NavigationDestination(icon: Icon(Icons.grid_view), label: 'Lainnya'),
      ]),
  );
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(
    stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots(),
    builder: (context, userSnap) {
      final role = userSnap.data?.data()?['role'] ?? 'warga';
      return ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
          color: const Color(0xff174b78), borderRadius: BorderRadius.circular(18)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Selamat datang di', style: TextStyle(color: Colors.white70)),
            Text('RT 08', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
            Text('Informasi dan pelayanan warga dalam satu aplikasi.',
              style: TextStyle(color: Colors.white)),
          ])),
        const SizedBox(height: 16),
        Text('Akses: $role', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Wrap(spacing: 10, runSpacing: 10, children: [
          FeatureTile(icon: Icons.people, label: 'Data warga'),
          FeatureTile(icon: Icons.account_balance_wallet, label: 'Kas RT'),
          FeatureTile(icon: Icons.mail, label: 'Surat pengantar'),
          FeatureTile(icon: Icons.campaign, label: 'Pengumuman'),
          FeatureTile(icon: Icons.report, label: 'Laporan lingkungan'),
          FeatureTile(icon: Icons.event, label: 'Kegiatan RT'),
        ]),
        const SizedBox(height: 18),
        const Text('Laporan terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const ReportsList(compact: true),
      ]);
    });
}
class FeatureTile extends StatelessWidget {
  final IconData icon; final String label;
  const FeatureTile({super.key, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => SizedBox(width: 155, child: Card(
    child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
      Icon(icon, size: 30, color: const Color(0xff174b78)), const SizedBox(height: 6),
      Text(label, textAlign: TextAlign.center)
    ]))));
}

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: const ReportsList(),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewReportPage())),
      icon: const Icon(Icons.add), label: const Text('Buat laporan')),
  );
}

class NewReportPage extends StatefulWidget {
  const NewReportPage({super.key});
  @override
  State<NewReportPage> createState() => _NewReportPageState();
}
class _NewReportPageState extends State<NewReportPage> {
  final location = TextEditingController(), detail = TextEditingController();
  final picker = ImagePicker();
  String category = 'Sampah menumpuk';
  XFile? photo; bool busy = false;
  final categories = const ['Sampah menumpuk','Banjir / genangan','Lampu jalan rusak',
    'Jalan rusak','Saluran air tersumbat','Pohon tumbang','Gangguan keamanan',
    'Kerusakan fasilitas umum','Lain-lain'];
  Future<void> choosePhoto() async {
    final p = await picker.pickImage(source: ImageSource.camera, imageQuality: 75);
    if (p != null) setState(() => photo = p);
  }
  Future<void> send() async {
    if (location.text.trim().isEmpty || detail.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi lokasi dan keterangan laporan.')));
      return;
    }
    setState(() => busy = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      String? photoUrl;
      if (photo != null) {
        final ref = FirebaseStorage.instance.ref('reports/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(File(photo!.path));
        photoUrl = await ref.getDownloadURL();
      }
      await FirebaseFirestore.instance.collection('reports').add({
        'userId': uid, 'category': category, 'location': location.text.trim(),
        'detail': detail.text.trim(), 'photoUrl': photoUrl, 'status': 'Menunggu',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil dikirim.'))); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengirim: $e')));
    }
    if (mounted) setState(() => busy = false);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Laporan lingkungan')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'Kategori'),
        items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) => setState(() => category = v!)),
      TextField(controller: location, decoration: const InputDecoration(labelText: 'Lokasi kejadian',
        hintText: 'Contoh: Gang 2 dekat pos ronda')),
      TextField(controller: detail, maxLines: 4, decoration: const InputDecoration(labelText: 'Keterangan')),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: choosePhoto, icon: const Icon(Icons.camera_alt),
        label: Text(photo == null ? 'Ambil foto bukti' : 'Foto terpilih: ${photo!.name}')),
      const SizedBox(height: 18),
      FilledButton(onPressed: busy ? null : send,
        child: Text(busy ? 'Mengirim...' : 'Kirim laporan')),
    ]),
  );
}

class ReportsList extends StatelessWidget {
  final bool compact;
  const ReportsList({super.key, this.compact = false});
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
    stream: FirebaseFirestore.instance.collection('reports').orderBy('createdAt', descending: true)
      .limit(compact ? 4 : 100).snapshots(),
    builder: (context, snap) {
      if (snap.hasError) return const Center(child: Text('Gagal memuat laporan.'));
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      if (snap.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(20),
        child: Text('Belum ada laporan.'));
      return ListView.builder(shrinkWrap: compact, physics: compact ? const NeverScrollableScrollPhysics() : null,
        itemCount: snap.data!.docs.length, itemBuilder: (context, i) {
          final doc = snap.data!.docs[i], d = doc.data();
          return Card(child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.report_problem)),
            title: Text(d['category'] ?? 'Laporan'),
            subtitle: Text('${d['location'] ?? '-'}\n${d['detail'] ?? ''}'),
            isThreeLine: true,
            trailing: StatusControl(id: doc.id, status: d['status'] ?? 'Menunggu'),
          ));
        });
    });
}

class StatusControl extends StatelessWidget {
  final String id, status;
  const StatusControl({super.key, required this.id, required this.status});
  @override
  Widget build(BuildContext context) => FutureBuilder<DocumentSnapshot<Map<String,dynamic>>>(
    future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get(),
    builder: (context, snap) {
      final admin = snap.data?.data()?['role'] == 'pengurus';
      if (!admin) return Chip(label: Text(status));
      return PopupMenuButton<String>(
        tooltip: 'Ubah status',
        onSelected: (v) => FirebaseFirestore.instance.collection('reports').doc(id).update({'status': v}),
        itemBuilder: (_) => ['Menunggu','Diproses','Selesai','Ditolak']
          .map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
        child: Chip(label: Text(status), avatar: const Icon(Icons.edit, size: 16)),
      );
    });
}

class AnnouncementsTab extends StatelessWidget {
  const AnnouncementsTab({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
    stream: FirebaseFirestore.instance.collection('announcements').orderBy('createdAt', descending: true).snapshots(),
    builder: (context, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Pengumuman RT', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ...snap.data!.docs.map((d) => Card(child: ListTile(
          leading: const Icon(Icons.campaign), title: Text(d.data()['title'] ?? ''),
          subtitle: Text(d.data()['body'] ?? '')))),
      ]);
    });
}

class AdminMenuTab extends StatelessWidget {
  const AdminMenuTab({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: const [
    Text('Layanan RT 08', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    ListTile(leading: Icon(Icons.people), title: Text('Data warga'), subtitle: Text('Modul tahap berikutnya')),
    ListTile(leading: Icon(Icons.account_balance_wallet), title: Text('Kas RT'), subtitle: Text('Modul tahap berikutnya')),
    ListTile(leading: Icon(Icons.mail), title: Text('Surat pengantar'), subtitle: Text('Modul tahap berikutnya')),
    ListTile(leading: Icon(Icons.event), title: Text('Kegiatan RT'), subtitle: Text('Modul tahap berikutnya')),
  ]);
}
