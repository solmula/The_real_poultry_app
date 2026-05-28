import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/providers/auth_provider.dart';
import '../../../../data/providers/farm_provider.dart';
import '../../../../data/providers/user_management_provider.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/farm_model.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserManagementProvider()..loadUsers(),
      child: const _UserManagementView(),
    );
  }
}

class _UserManagementView extends StatelessWidget {
  const _UserManagementView();

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.cardDark       : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight      : AppColors.textPrimary;
    final provider  = context.watch<UserManagementProvider>();
    final auth      = context.read<AuthProvider>();
    final farms     = context.watch<FarmProvider>().farms;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'User Management',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
        ),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          if (provider.isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => context.read<UserManagementProvider>().loadUsers(),
              tooltip: 'Refresh',
            ),
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: AppColors.primary),
            onPressed: () => _showInviteDialog(context, auth, farms),
            tooltip: 'Invite user',
          ),
          if (auth.isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.domain_add_rounded, color: AppColors.primary),
              onPressed: () => _showFarmOnboardingDialog(context),
              tooltip: 'Create farm admin',
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : provider.status == UserMgmtStatus.error && provider.users.isEmpty
              ? _ErrorView(
                  message: provider.error ?? 'Unknown error',
                  onRetry: () => context.read<UserManagementProvider>().loadUsers(),
                  isDark: isDark,
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => context.read<UserManagementProvider>().loadUsers(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    children: [
                      _SummaryRow(provider: provider, isDark: isDark),
                      const SizedBox(height: 20),
                      _SectionLabel(
                        text: '${provider.users.length} USERS',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      if (provider.users.isEmpty)
                        _EmptyView(isDark: isDark)
                      else
                        ...provider.users.map(
                          (u) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _UserCard(
                              user: u,
                              currentUid: auth.user?.uid ?? '',
                              isDark: isDark,
                              onRoleChanged: (role) => _changeRole(context, u, role),
                              onToggleDisabled: () => _toggleDisabled(context, u),
                              onDelete: () => _deleteUser(context, u),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _changeRole(BuildContext context, UserModel user, String newRole) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Role'),
        content: Text('Change ${user.email} to ${_roleLabel(newRole)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Change'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final err = await context.read<UserManagementProvider>().changeRole(user.uid, newRole);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Role updated to ${_roleLabel(newRole)}'),
          backgroundColor: err != null ? AppColors.statusCritical : AppColors.statusGood,
        ),
      );
    }
  }

  Future<void> _toggleDisabled(BuildContext context, UserModel user) async {
    final action = user.disabled ? 'Enable' : 'Disable';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$action User'),
        content: Text(
          '$action account for ${user.email}?'
          '${user.disabled ? '' : '\n\nThey will not be able to access the app until re-enabled.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: user.disabled ? AppColors.statusGood : AppColors.statusWarning,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final err = await context.read<UserManagementProvider>().toggleDisabled(user.uid, !user.disabled);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'User ${action.toLowerCase()}d'),
          backgroundColor: err != null ? AppColors.statusCritical : AppColors.statusGood,
        ),
      );
    }
  }

  Future<void> _deleteUser(BuildContext context, UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Remove ${user.email} from the system?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.statusWarning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.statusWarning, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This removes their app access record. Their Firebase Auth account persists — contact support for full deletion.',
                      style: TextStyle(fontSize: 12, color: AppColors.statusWarning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusCritical),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final err = await context.read<UserManagementProvider>().deleteUser(user.uid);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'User removed'),
          backgroundColor: err != null ? AppColors.statusCritical : AppColors.statusGood,
        ),
      );
    }
  }

  void _showInviteDialog(BuildContext context, AuthProvider auth, List<FarmModel> farms) {
    showDialog(
      context: context,
      builder: (ctx) => _InviteDialog(
        auth: auth,
        farms: farms,
        onInvite: (email, role, farmId) async {
          return await ctx.read<UserManagementProvider>().inviteUser(
                email: email,
                role: role,
                farmId: farmId,
              );
        },
      ),
    );
  }

  void _showFarmOnboardingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _FarmOnboardingDialog(),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':    return 'Admin';
      case 'operator': return 'Operator';
      case 'viewer':   return 'Viewer';
      default:         return role;
    }
  }
}

// ── Summary Row ───────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final UserManagementProvider provider;
  final bool isDark;
  const _SummaryRow({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryChip(label: 'Admins',    count: provider.adminCount,    color: AppColors.primary,       isDark: isDark),
        const SizedBox(width: 8),
        _SummaryChip(label: 'Operators', count: provider.operatorCount, color: AppColors.severityInfo,  isDark: isDark),
        const SizedBox(width: 8),
        _SummaryChip(label: 'Viewers',   count: provider.viewerCount,   color: AppColors.statusOffline, isDark: isDark),
        if (provider.disabledCount > 0) ...[
          const SizedBox(width: 8),
          _SummaryChip(label: 'Disabled', count: provider.disabledCount, color: AppColors.statusCritical, isDark: isDark),
        ],
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isDark;
  const _SummaryChip({required this.label, required this.count, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Text('$count', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.85))),
        ],
      ),
    );
  }
}

// ── User Card ─────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final UserModel user;
  final String currentUid;
  final bool isDark;
  final void Function(String role) onRoleChanged;
  final VoidCallback onToggleDisabled;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.currentUid,
    required this.isDark,
    required this.onRoleChanged,
    required this.onToggleDisabled,
    required this.onDelete,
  });

  bool get isCurrentUser => user.uid == currentUid;

  Color get _roleColor {
    if (user.disabled) return AppColors.statusOffline;
    switch (user.role) {
      case 'admin':    return AppColors.primary;
      case 'operator': return AppColors.severityInfo;
      default:         return AppColors.statusOffline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: user.disabled
            ? Border.all(color: AppColors.statusCritical.withOpacity(0.3))
            : isCurrentUser
                ? Border.all(color: AppColors.primary.withOpacity(0.4))
                : null,
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: _roleColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(user.disabled ? Icons.block_rounded : Icons.person_rounded, color: _roleColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: user.disabled ? AppColors.textSecondary : textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('YOU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ),
                        ],
                        if (user.disabled) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.statusCritical.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('DISABLED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.statusCritical)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: _roleColor.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
                          child: Text(user.roleLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _roleColor)),
                        ),
                        const SizedBox(width: 10),
                        if (user.lastLogin != null)
                          Text('Last seen ${_timeAgo(user.lastLogin!)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isCurrentUser)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
                  onSelected: (v) {
                    if (v == 'toggle') onToggleDisabled();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            user.disabled ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                            size: 18,
                            color: user.disabled ? AppColors.statusGood : AppColors.statusWarning,
                          ),
                          const SizedBox(width: 10),
                          Text(user.disabled ? 'Enable' : 'Disable'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.statusCritical),
                          SizedBox(width: 10),
                          Text('Delete', style: TextStyle(color: AppColors.statusCritical)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (!isCurrentUser && !user.disabled) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Role:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 10),
                ..._roles.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _RoleChip(
                      label: r['label']!,
                      selected: user.role == r['value'],
                      color: _colorFor(r['value']!),
                      onTap: user.role == r['value'] ? null : () => onRoleChanged(r['value']!),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (user.createdAt != null) ...[
            const SizedBox(height: 8),
            Text('Joined ${_dateStr(user.createdAt!)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  static const _roles = [
    {'label': 'Admin',    'value': 'admin'},
    {'label': 'Operator', 'value': 'operator'},
    {'label': 'Viewer',   'value': 'viewer'},
  ];

  Color _colorFor(String role) {
    switch (role) {
      case 'admin':    return AppColors.primary;
      case 'operator': return AppColors.severityInfo;
      default:         return AppColors.statusOffline;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inHours < 1)    return '${diff.inMinutes}m ago';
    if (diff.inDays < 1)     return '${diff.inHours}h ago';
    if (diff.inDays < 30)    return '${diff.inDays}d ago';
    return _dateStr(dt);
  }

  String _dateStr(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

// ── Role Chip ─────────────────────────────────────────────────────────────────
class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;
  const _RoleChip({required this.label, required this.selected, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : color),
        ),
      ),
    );
  }
}

// ── Invite Dialog ─────────────────────────────────────────────────────────────
class _InviteDialog extends StatefulWidget {
  final AuthProvider auth;
  final List<FarmModel> farms;
  final Future<String?> Function(String email, String role, String? farmId) onInvite;
  const _InviteDialog({required this.auth, required this.farms, required this.onInvite});

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final _formKey       = GlobalKey<FormState>();
  final _emailCtrl     = TextEditingController();
  String _role = 'operator';
  bool _loading = false;
  String? _error;
  String? _selectedFarmId;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  static const Map<String, String> _roleDescriptions = {
    'operator': 'Can view all data and send manual commands. Cannot edit thresholds.',
    'viewer':   'Read-only access. Cannot send commands or edit anything.',
  };

  static const Map<String, Color> _roleColors = {
    'admin':    AppColors.primary,
    'operator': AppColors.severityInfo,
    'viewer':   AppColors.statusOffline,
  };

  @override
  Widget build(BuildContext context) {
    if (widget.auth.isSuperAdmin && _selectedFarmId == null && widget.farms.isNotEmpty) {
      _selectedFarmId = widget.farms.first.id;
    }

    final roleColor = _roleColors[_role] ?? AppColors.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invite New User', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      Text('Create a new account', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, size: 18)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text('Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: ['operator', 'viewer'].map((r) {
                  final selected = _role == r;
                  final color = _roleColors[r]!;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => _role = r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? color : color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            r[0].toUpperCase() + r.substring(1),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : color),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (widget.auth.isSuperAdmin) ...[
                const SizedBox(height: 16),
                const Text('Farm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedFarmId,
                  items: widget.farms
                      .map((farm) => DropdownMenuItem(
                            value: farm.id,
                            child: Text('${farm.name} (${farm.subscriptionPlan})'),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedFarmId = value),
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.domain_rounded, size: 18)),
                  validator: (value) => value == null || value.isEmpty ? 'Select a farm' : null,
                ),
              ],
              const SizedBox(height: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: roleColor.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: roleColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_roleDescriptions[_role]!, style: TextStyle(fontSize: 12, color: roleColor.withOpacity(0.9))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.statusCritical.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.statusCritical)),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Create User'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final err = await widget.onInvite(
      _emailCtrl.text.trim(),
      _role,
      widget.auth.isSuperAdmin ? _selectedFarmId : widget.auth.farmId,
    );

    if (!mounted) return;
    if (err != null) {
      setState(() { _loading = false; _error = err; });
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User created successfully'), backgroundColor: AppColors.statusGood),
      );
    }
  }
}

class _FarmOnboardingDialog extends StatefulWidget {
  const _FarmOnboardingDialog();

  @override
  State<_FarmOnboardingDialog> createState() => _FarmOnboardingDialogState();
}

class _FarmOnboardingDialogState extends State<_FarmOnboardingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _farmNameCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _planCtrl = TextEditingController(text: 'starter');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _farmNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _planCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create Farm Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const Text('Super admins create a new farm and its first admin.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _farmNameCtrl,
                decoration: const InputDecoration(labelText: 'Farm Name', prefixIcon: Icon(Icons.domain_rounded, size: 18)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Farm name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _adminEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Admin Email', prefixIcon: Icon(Icons.email_outlined, size: 18)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Admin email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _planCtrl,
                decoration: const InputDecoration(labelText: 'Subscription Plan', prefixIcon: Icon(Icons.workspace_premium_outlined, size: 18)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Plan is required' : null,
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.statusCritical.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.statusCritical)),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Create Farm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final err = await context.read<UserManagementProvider>().createFarmAdmin(
      farmName: _farmNameCtrl.text.trim(),
      adminEmail: _adminEmailCtrl.text.trim(),
      subscriptionPlan: _planCtrl.text.trim(),
    );

    if (!mounted) return;
    if (err != null) {
      setState(() { _loading = false; _error = err; });
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farm admin created'), backgroundColor: AppColors.statusGood),
      );
    }
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2));
  }
}

class _EmptyView extends StatelessWidget {
  final bool isDark;
  const _EmptyView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.group_outlined, size: 48, color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 12),
          const Text('No users found', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isDark;
  const _ErrorView({required this.message, required this.onRetry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.statusCritical),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}