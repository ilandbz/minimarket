import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _error;

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
      final response = await ApiService.get('users');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _users = data.map((u) => UserModel.fromJson(u)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Error al cargar los usuarios.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  void _openUserForm({UserModel? user}) {
    showDialog(
      context: context,
      builder: (context) {
        return UserFormDialog(
          user: user,
          onSaveSuccess: _fetchUsers,
        );
      },
    );
  }

  void _deleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar Usuario?'),
        content: Text('¿Estás seguro de eliminar al usuario "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final response = await ApiService.delete('users/${user.id}');
                if (response.statusCode == 200 && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuario eliminado exitosamente.')),
                  );
                  _fetchUsers();
                } else if (mounted) {
                  final data = jsonDecode(response.body);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(data['message'] ?? 'Error al eliminar usuario.'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios / Vendedores'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: AppTheme.error)),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _fetchUsers, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final u = _users[index];
                      final isAdmin = u.role == 'admin';
                      final isActive = u.status == 'active';

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isAdmin ? AppTheme.primary.withOpacity(0.1) : AppTheme.accent.withOpacity(0.1),
                            child: Icon(
                              isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_outline_rounded,
                              color: isAdmin ? AppTheme.primary : AppTheme.accent,
                            ),
                          ),
                          title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${u.email} | Rol: ${u.role.toUpperCase()}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Badge de estado
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isActive ? 'Activo' : 'Inactivo',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                                onPressed: () => _openUserForm(user: u),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                                onPressed: () => _deleteUser(u),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openUserForm(),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class UserFormDialog extends StatefulWidget {
  final UserModel? user;
  final VoidCallback onSaveSuccess;

  const UserFormDialog({super.key, this.user, required this.onSaveSuccess});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _role = 'vendedor'; // admin, vendedor
  String _status = 'active'; // active, inactive

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      final u = widget.user!;
      _nameController.text = u.name;
      _emailController.text = u.email;
      _role = u.role;
      _status = u.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'role': _role,
      'status': _status,
    };

    if (_passwordController.text.isNotEmpty || widget.user == null) {
      data['password'] = _passwordController.text.trim();
    }

    try {
      final response = widget.user == null
          ? await ApiService.post('users', data)
          : await ApiService.put('users/${widget.user!.id}', data);

      if ((response.statusCode == 200 || response.statusCode == 201) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.user == null ? 'Usuario creado.' : 'Usuario actualizado.')),
        );
        widget.onSaveSuccess();
        Navigator.pop(context);
      } else if (mounted) {
        final errData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errData['message'] ?? 'Error al guardar usuario.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? 'Nuevo Vendedor/Admin' : 'Editar Usuario'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre Completo'),
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: widget.user == null ? 'Contraseña' : 'Nueva Contraseña (Opcional)',
                  hintText: widget.user == null ? 'Mínimo 6 caracteres' : 'Dejar en blanco para no cambiar',
                ),
                obscureText: true,
                validator: (val) {
                  if (widget.user == null && (val == null || val.isEmpty)) {
                    return 'Requerido';
                  }
                  if (val != null && val.isNotEmpty && val.length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Selección de Rol
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(value: 'vendedor', child: Text('Vendedor')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                ],
                onChanged: (val) => setState(() => _role = val!),
              ),
              const SizedBox(height: 10),

              // Selección de Estado
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Activo')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactivo')),
                ],
                onChanged: (val) => setState(() => _status = val!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
