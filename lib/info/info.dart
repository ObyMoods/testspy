import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../manager/change_password_page.dart';

class MyInfoPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final String coins;
  
  const MyInfoPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
    required this.coins,
  });

  @override
  State<MyInfoPage> createState() => _MyInfoPageState();
}

class _MyInfoPageState extends State<MyInfoPage> with TickerProviderStateMixin {
  final Color _primaryPink = const Color(0xFFFF4081);
  final Color _softPink = const Color(0xFFFF80AB);
  final Color _bgDark = const Color(0xFF120509);
  final Color _cardDark = const Color(0xFF1A1A1A);
  final Color _cardDarker = const Color(0xFF0D0D0D);
  final Color _goldColor = const Color(0xFFFFD700);
  
  final String baseUrl = "http://yaanzxsuikahost.omdhanebew.my.id:2275";

  File? _profileImage;
  bool showUsername = false;
  bool showPassword = false;
  bool showSessionKey = false;
  
  String _userBio = "";
  String _userName = "";
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadProfileImage();
    _loadUserData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get-user-profile?username=${widget.username}&key=${widget.sessionKey}"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _userBio = data['bio'] ?? "Halo! Saya pengguna Public Lounge";
            _userName = data['name'] ?? widget.username;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateBio(String newBio) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/update-bio"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'username': widget.username,
          'bio': newBio,
          'key': widget.sessionKey,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          _userBio = newBio;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bio berhasil diperbarui"), backgroundColor: Colors.green),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? "Gagal update bio"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal update bio: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateName(String newName) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/update-name"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'username': widget.username,
          'name': newName,
          'key': widget.sessionKey,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          _userName = newName;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nama berhasil diperbarui"), backgroundColor: Colors.green),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? "Gagal update nama"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal update nama: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (image != null) {
      setState(() => _isLoading = true);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_${widget.username}', image.path);
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/update-profile-picture"),
      );
      request.fields['username'] = widget.username;
      request.fields['key'] = widget.sessionKey;
      request.files.add(await http.MultipartFile.fromPath('avatar', image.path));
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);
      
      if (data['success'] == true) {
        setState(() {
          _profileImage = File(image.path);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto profil berhasil diupdate"), backgroundColor: Colors.green),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? "Gagal update foto"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image_${widget.username}');

    if (path != null && File(path).existsSync()) {
      setState(() {
        _profileImage = File(path);
      });
    }
  }

  void _showEditBioDialog() {
    final TextEditingController bioController = TextEditingController(text: _userBio);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Bio", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: bioController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Tulis bio Anda...",
            hintStyle: const TextStyle(color: Colors.white54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF4081)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF4081)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (bioController.text.trim().isNotEmpty) {
                _updateBio(bioController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryPink),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog() {
    final TextEditingController nameController = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Nama", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Masukkan nama Anda",
            hintStyle: const TextStyle(color: Colors.white54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF4081)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF4081)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (nameController.text.trim().isNotEmpty) {
                _updateName(nameController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryPink),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  String _mask(String text, {int show = 2}) {
    if (text.length <= show) return "*" * text.length;
    return text.substring(0, show) + "•" * (text.length - show);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4081)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 20),
                      _buildBioCard(),
                      const SizedBox(height: 24),
                      _buildInfoSection(),
                      const SizedBox(height: 24),
                      _buildChangePasswordButton(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _primaryPink, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _primaryPink.withOpacity(0.3),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 58,
                backgroundColor: _cardDark,
                backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null
                    ? Text(
                        widget.username.isNotEmpty ? widget.username[0].toUpperCase() : "?",
                        style: const TextStyle(
                          fontSize: 42,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _primaryPink,
                  shape: BoxShape.circle,
                  border: Border.all(color: _bgDark, width: 2),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showEditNameDialog,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.edit, color: _softPink, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _primaryPink.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.role.toUpperCase(),
            style: TextStyle(
              color: _primaryPink,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBioCard() {
    return GestureDetector(
      onTap: _showEditBioDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primaryPink.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryPink.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.info_outline, color: _primaryPink, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Bio", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    _userBio,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _softPink, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _infoTile(
            icon: Icons.person,
            label: "Username",
            value: showUsername ? widget.username : _mask(widget.username),
            onToggle: () => setState(() => showUsername = !showUsername),
          ),
          _divider(),
          _infoTile(
            icon: Icons.lock,
            label: "Password",
            value: showPassword ? widget.password : "•" * widget.password.length,
            onToggle: () => setState(() => showPassword = !showPassword),
          ),
          _divider(),
          _staticTile(
            icon: FontAwesomeIcons.shieldAlt,
            label: "Role",
            value: widget.role.toUpperCase(),
          ),
          _divider(),
          _staticTile(
            icon: Icons.calendar_today,
            label: "Expired Date",
            value: widget.expiredDate,
          ),
          _divider(),
          _staticTile(
            icon: FontAwesomeIcons.coins,
            label: "Balance",
            value: "${widget.coins} Coins",
            valueColor: _goldColor,
          ),
          _divider(),
          _infoTile(
            icon: Icons.vpn_key,
            label: "Session Key",
            value: showSessionKey ? widget.sessionKey : _mask(widget.sessionKey, show: 6),
            onToggle: () => setState(() => showSessionKey = !showSessionKey),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onToggle,
  }) {
    final isMasked = value.contains("•");
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _primaryPink.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _primaryPink, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isMasked ? Icons.visibility : Icons.visibility_off,
              color: _softPink,
              size: 20,
            ),
            onPressed: onToggle,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _staticTile({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _primaryPink.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _primaryPink, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(color: valueColor, fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withOpacity(0.08),
    );
  }

  Widget _buildChangePasswordButton() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [_primaryPink, _softPink],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _primaryPink.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.lock_reset, color: Colors.white),
          label: const Text(
            "CHANGE PASSWORD",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangePasswordPage(
                  username: widget.username,
                  sessionKey: widget.sessionKey,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
