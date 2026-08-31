import 'package:flutter/material.dart';
import 'package:admin_web/core/utils/snackbar_helper.dart';
import '../../../core/utils/snackbar_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/admin_api_service.dart';
import '../admin_user_detail_screen.dart';

class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  final AdminApiService _apiService = AdminApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;
  
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'date'

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final data = await _apiService.getUsers();
      if (mounted) {
        setState(() {
          _users = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AddUserDialog(onUserAdded: _fetchUsers),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EditUserDialog(user: user, onUserUpdated: _fetchUsers),
    );
  }

  Future<void> _toggleUserStatus(int id, String currentStatus, Map<String, dynamic> user) async {
    try {
      final newStatus = currentStatus == 'active' ? 'inactive' : 'active';
      // We send the existing data with just the status changed
      final updatedData = Map<String, dynamic>.from(user);
      updatedData['status'] = newStatus;
      await _apiService.updateUser(id, updatedData);
      _fetchUsers();
    } catch (e) {
      debugPrint("Toggle status error: $e");
      if (mounted) {
        SnackbarHelper.showError(context, e.toString());
      }
    }
  }

  Future<void> _deleteUser(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to permanently delete $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteUser(id);
        _fetchUsers();
        if (mounted) {
          SnackbarHelper.showSuccess(context, 'User deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          SnackbarHelper.showError(context, e.toString());
        }
      }
    }
  }

  Future<void> _showResetPasswordDialog(int id, String name) async {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Password for $name'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: 'New Password'),
            validator: (val) => (val == null || val.length < 6) ? 'At least 6 chars required' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _apiService.resetUserPassword(id, passwordController.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    SnackbarHelper.showSuccess(context, 'Password reset successfully');
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    SnackbarHelper.showError(context, e.toString());
                  }
                }
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryDark));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.accentDanger, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppTheme.accentDanger)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchUsers, child: const Text('Retry')),
          ],
        ),
      );
    }

    List<dynamic> filteredUsers = _users.where((user) {
      final search = _searchQuery.toLowerCase();
      final name = (user['name'] ?? '').toString().toLowerCase();
      final phone = (user['mobile_number'] ?? '').toString().toLowerCase();
      final username = (user['username'] ?? '').toString().toLowerCase();
      return name.contains(search) || phone.contains(search) || username.contains(search);
    }).toList();

    if (_sortBy == 'name') {
      filteredUsers.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
    } else if (_sortBy == 'date') {
      filteredUsers.sort((a, b) {
        final aDate = a['created_at'] ?? '';
        final bDate = b['created_at'] ?? '';
        return bDate.toString().compareTo(aDate.toString());
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
        backgroundColor: AppTheme.primaryDark,
      ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Employees List',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: _fetchUsers,
                  tooltip: 'Refresh',
                )
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by name or number...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      filled: true,
                      fillColor: AppTheme.surfaceDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      dropdownColor: AppTheme.surfaceDark,
                      style: const TextStyle(color: Colors.white),
                      icon: const Icon(Icons.sort, color: Colors.white54),
                      onChanged: (String? newValue) {
                        if (newValue != null) setState(() => _sortBy = newValue);
                      },
                      items: const [
                        DropdownMenuItem(value: 'name', child: Text('Name')),
                        DropdownMenuItem(value: 'date', child: Text('Newest')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: filteredUsers.isEmpty
                  ? const Center(child: Text('No users found.', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final id = user['id'] as int;
                        final name = user['name'] ?? 'Unknown';
                        final username = user['username'] ?? '';
                        final mobile = user['mobile_number'] ?? '';
                        final role = user['role'] ?? 'user';
                        final designation = user['designation'] ?? 'No Designation';
                        final status = user['status'] ?? 'inactive';
                        final isActive = status == 'active';

                        return Card(
                          color: AppTheme.surfaceDark,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminUserDetailScreen(user: user),
                                ),
                              );
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                              child: Icon(isActive ? Icons.person : Icons.person_off, color: isActive ? Colors.green : Colors.red),
                            ),
                            title: Text('$name (@$username)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('$mobile | $designation', style: const TextStyle(color: Colors.white70)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: role == 'admin' ? AppTheme.primaryDark.withOpacity(0.3) : Colors.white10,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(role.toUpperCase(), style: TextStyle(fontSize: 10, color: role == 'admin' ? Colors.blueAccent : Colors.white54)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Status: $status', style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.white54),
                              color: AppTheme.surfaceDark,
                              onSelected: (val) {
                                if (val == 'toggle') _toggleUserStatus(id, status, user);
                                else if (val == 'edit') _showEditUserDialog(user);
                                else if (val == 'delete') _deleteUser(id, name);
                                else if (val == 'reset') _showResetPasswordDialog(id, name);
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Row(
                                    children: [
                                      Icon(isActive ? Icons.person_off : Icons.person, color: Colors.white70, size: 20),
                                      const SizedBox(width: 8),
                                      Text(isActive ? 'Deactivate' : 'Activate', style: const TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, color: Colors.white70, size: 20),
                                      SizedBox(width: 8),
                                      Text('Edit User', style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'reset',
                                  child: Row(
                                    children: [
                                      Icon(Icons.lock_reset, color: Colors.white70, size: 20),
                                      SizedBox(width: 8),
                                      Text('Reset Password', style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red, size: 20),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: (index * 30).ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddUserDialog extends StatefulWidget {
  final VoidCallback onUserAdded;
  const _AddUserDialog({required this.onUserAdded});

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final AdminApiService _apiService = AdminApiService();
  
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _mobile = TextEditingController();
  final _name = TextEditingController();
  final _designation = TextEditingController();
  final _employeeId = TextEditingController();
  final _notes = TextEditingController();
  
  String _department = 'Sales';
  String _role = 'user';
  String _status = 'active';
  bool _isLoading = false;
  final Map<String, String> _fieldErrors = {};

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _fieldErrors.clear();
    });

    try {
      await _apiService.createUser({
        'username': _username.text.trim(),
        'password': _password.text,
        'mobile_number': _mobile.text.trim(),
        'name': _name.text.trim(),
        'designation': _designation.text.trim(),
        'employee_id': _employeeId.text.trim(),
        'department': _department,
        'description': _notes.text.trim(),
        'role': _role,
        'status': _status,
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onUserAdded();
      }
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() {
          e.errors.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              _fieldErrors[key] = value.first.toString();
            } else {
              _fieldErrors[key] = value.toString();
            }
          });
        });
        SnackbarHelper.showError(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 650,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Dark slate matching screenshot
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E88E5), // Blue header
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Add New User', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Create a new user profile with complete details.', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Details Section
                      _buildSectionHeader(Icons.person_outline, 'Personal Details'),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildTextField(_name, 'Full Name', Icons.person, true, errorText: _fieldErrors['name'])),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTextField(_mobile, 'Mobile Number (E164)', Icons.phone, true, prefixText: '+91 ', errorText: _fieldErrors['mobile_number'])),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: _buildTextField(_username, '@ Email ID / Username', Icons.alternate_email, true, errorText: _fieldErrors['username'])),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTextField(_password, 'Password', Icons.lock_outline, true, obscureText: true, errorText: _fieldErrors['password'])),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Work Details Section
                      _buildSectionHeader(Icons.work_outline, 'Work Details'),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildTextField(_employeeId, 'Employee ID', Icons.badge_outlined, false, errorText: _fieldErrors['employee_id'])),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTextField(_designation, 'Designation', Icons.work_outline, false, errorText: _fieldErrors['designation'])),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: _buildDropdown('Department', Icons.business, _department, ['Sales', 'Support', 'IT', 'HR', 'Admin'], (val) => setState(() => _department = val!))),
                                const SizedBox(width: 16),
                                Expanded(child: _buildDropdown('Role', Icons.admin_panel_settings_outlined, _role, ['user', 'admin'], (val) => setState(() => _role = val!))),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(_notes, 'Description / Notes', Icons.notes, false, errorText: _fieldErrors['description']),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Active Status Switch
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          border: Border.all(color: Colors.white10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SwitchListTile(
                          title: const Text('Active Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: const Text('User can log in and use the app', style: TextStyle(color: Colors.green, fontSize: 12)),
                          value: _status == 'active',
                          onChanged: (val) => setState(() => _status = val ? 'active' : 'inactive'),
                          activeColor: Colors.green,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context), 
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5), // Blue button
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle, size: 20),
                    label: const Text('Add User', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1E88E5), size: 24),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Color(0xFF1E88E5), fontSize: 18, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isRequired, {bool obscureText = false, String? prefixText, String? errorText}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        prefixText: prefixText,
        prefixStyle: const TextStyle(color: Colors.white, fontSize: 16),
        filled: true,
        fillColor: Colors.transparent,
        errorText: errorText,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blue)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
      ),
      validator: isRequired ? (val) => val == null || val.isEmpty ? 'Required' : null : null,
    );
  }

  Widget _buildDropdown(String label, IconData icon, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF0F172A),
      style: const TextStyle(color: Colors.white),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.transparent,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blue)),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }
}

class _EditUserDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onUserUpdated;
  const _EditUserDialog({required this.user, required this.onUserUpdated});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final AdminApiService _apiService = AdminApiService();
  
  late TextEditingController _username;
  late TextEditingController _mobile;
  late TextEditingController _name;
  late TextEditingController _designation;
  late TextEditingController _employeeId;
  late TextEditingController _notes;
  late String _department;
  late  String _role = 'user';
  String _status = 'active';
  bool _isLoading = false;
  final Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: widget.user['username']);
    _mobile = TextEditingController(text: widget.user['mobile_number']);
    _name = TextEditingController(text: widget.user['name']);
    _designation = TextEditingController(text: widget.user['designation']);
    _employeeId = TextEditingController(text: widget.user['employee_id']?.toString() ?? '');
    _notes = TextEditingController(text: widget.user['description'] ?? '');
    
    _department = widget.user['department'] ?? 'Sales';
    _role = widget.user['role'] ?? 'user';
    _status = widget.user['status'] ?? 'active';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _fieldErrors.clear();
    });

    try {
      final updatedData = Map<String, dynamic>.from(widget.user);
      updatedData['username'] = _username.text.trim();
      updatedData['mobile_number'] = _mobile.text.trim();
      updatedData['name'] = _name.text.trim();
      updatedData['designation'] = _designation.text.trim();
      updatedData['employee_id'] = _employeeId.text.trim();
      updatedData['department'] = _department;
      updatedData['description'] = _notes.text.trim();
      updatedData['role'] = _role;
      updatedData['status'] = _status;

      await _apiService.updateUser(widget.user['id'], updatedData);
      
      if (mounted) {
        Navigator.pop(context);
        widget.onUserUpdated();
      }
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() {
          e.errors.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              _fieldErrors[key] = value.first.toString();
            } else {
              _fieldErrors[key] = value.toString();
            }
          });
        });
        SnackbarHelper.showError(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 650,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E88E5), // Blue header
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.edit, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Edit User', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Update the user profile details.', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(Icons.person_outline, 'Personal Details'),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildTextField(_name, 'Full Name', Icons.person, true, errorText: _fieldErrors['name'])),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTextField(_mobile, 'Mobile Number', Icons.phone, true, errorText: _fieldErrors['mobile_number'])),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: _buildTextField(_username, '@ Email ID / Username', Icons.alternate_email, true, errorText: _fieldErrors['username'])),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      _buildSectionHeader(Icons.work_outline, 'Work Details'),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildTextField(_employeeId, 'Employee ID', Icons.badge_outlined, false, errorText: _fieldErrors['employee_id'])),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTextField(_designation, 'Designation', Icons.work_outline, false, errorText: _fieldErrors['designation'])),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: _buildDropdown('Department', Icons.business, _department, ['Sales', 'Support', 'IT', 'HR', 'Admin'], (val) => setState(() => _department = val!))),
                                const SizedBox(width: 16),
                                Expanded(child: _buildDropdown('Role', Icons.admin_panel_settings_outlined, _role, ['user', 'admin'], (val) => setState(() => _role = val!))),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(_notes, 'Description / Notes', Icons.notes, false, errorText: _fieldErrors['description']),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
                        child: SwitchListTile(
                          title: const Text('Active Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: const Text('User can log in and use the app', style: TextStyle(color: Colors.green, fontSize: 12)),
                          value: _status == 'active',
                          onChanged: (val) => setState(() => _status = val ? 'active' : 'inactive'),
                          activeColor: Colors.green,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white10))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context), 
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5), // Blue button
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle, size: 20),
                    label: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1E88E5), size: 24),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Color(0xFF1E88E5), fontSize: 18, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isRequired, {bool obscureText = false, String? errorText}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.transparent,
        errorText: errorText,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blue)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
      ),
      validator: isRequired ? (val) => val == null || val.isEmpty ? 'Required' : null : null,
    );
  }

  Widget _buildDropdown(String label, IconData icon, String value, List<String> items, Function(String?) onChanged) {
    if (!items.contains(value)) items.add(value); // Safeguard for existing unknown departments
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF0F172A),
      style: const TextStyle(color: Colors.white),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.transparent,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blue)),
      ),
      items: items.toSet().map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }
}



