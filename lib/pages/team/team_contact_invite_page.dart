import 'package:flutter/material.dart';
import 'package:watermark_camera/models/phone_contact.dart';
import 'package:watermark_camera/models/team.dart';

class TeamContactInvitePage extends StatefulWidget {
  const TeamContactInvitePage({super.key, required this.team});

  final Team team;

  @override
  State<TeamContactInvitePage> createState() => _TeamContactInvitePageState();
}

class _TeamContactInvitePageState extends State<TeamContactInvitePage> {
  static const _primaryBlue = Color(0xFF1677FF);

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _sectionKeys = <String, GlobalKey>{};
  final _addedContactIds = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<PhoneContact> get _filteredContacts {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return kMockPhoneContacts;
    return kMockPhoneContacts
        .where(
          (contact) =>
              contact.name.contains(keyword) || contact.phone.contains(keyword),
        )
        .toList(growable: false);
  }

  Map<String, List<PhoneContact>> get _groupedContacts {
    final grouped = <String, List<PhoneContact>>{};
    for (final contact in _filteredContacts) {
      grouped.putIfAbsent(contact.section, () => []).add(contact);
    }
    for (final contacts in grouped.values) {
      contacts.sort((a, b) => a.name.compareTo(b.name));
    }
    return grouped;
  }

  List<String> get _visibleSections {
    final sections = _groupedContacts.keys.toList(growable: false);
    sections.sort((a, b) {
      final ai = kPhoneContactIndexLetters.indexOf(a);
      final bi = kPhoneContactIndexLetters.indexOf(b);
      if (ai == -1 && bi == -1) return a.compareTo(b);
      if (ai == -1) return 1;
      if (bi == -1) return -1;
      return ai.compareTo(bi);
    });
    return sections;
  }

  GlobalKey _keyForSection(String section) {
    return _sectionKeys.putIfAbsent(section, GlobalKey.new);
  }

  void _scrollToSection(String section) {
    if (!_visibleSections.contains(section)) return;
    final context = _keyForSection(section).currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: 0,
    );
  }

  void _addContact(PhoneContact contact) {
    if (_addedContactIds.contains(contact.id)) return;
    setState(() => _addedContactIds.add(contact.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已向${contact.name}发送添加邀请')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = _visibleSections;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          '从手机通讯录添加',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: '搜索',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey.shade500,
                      size: 22,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F6F8),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Text(
                  '添加的成员将收到免费短信通知',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ),
              Expanded(
                child: sections.isEmpty
                    ? Center(
                        child: Text(
                          '未找到匹配的联系人',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(right: 28, bottom: 16),
                        itemCount: sections.length,
                        itemBuilder: (context, index) {
                          final section = sections[index];
                          final contacts = _groupedContacts[section]!;
                          return Column(
                            key: _keyForSection(section),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                color: const Color(0xFFF5F6F8),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  section,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              for (final contact in contacts)
                                _ContactRow(
                                  contact: contact,
                                  added: _addedContactIds.contains(contact.id),
                                  onAdd: () => _addContact(contact),
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
          Positioned(
            right: 4,
            top: 96,
            bottom: 16,
            child: _AlphabetIndex(
              letters: kPhoneContactIndexLetters,
              onTap: _scrollToSection,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.contact,
    required this.added,
    required this.onAdd,
  });

  final PhoneContact contact;
  final bool added;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contact.phone,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: added ? null : onAdd,
            style: TextButton.styleFrom(
              foregroundColor: _TeamContactInvitePageState._primaryBlue,
              disabledForegroundColor: Colors.grey.shade400,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              added ? '已添加' : '添加',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlphabetIndex extends StatelessWidget {
  const _AlphabetIndex({
    required this.letters,
    required this.onTap,
  });

  final List<String> letters;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final letter in letters)
            GestureDetector(
              onTap: () => onTap(letter),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.5),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
