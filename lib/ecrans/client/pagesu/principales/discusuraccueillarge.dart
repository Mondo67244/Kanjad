import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/services/providers/messageprovider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:kanjad/ecrans/commercial/accueilcommercialgrand.dart';

// Version grand écran du dashboard client pour les discussions
class DiscusuraccueilLarge extends StatefulWidget {
  const DiscusuraccueilLarge({super.key});

  @override
  State<DiscusuraccueilLarge> createState() => _DiscusuraccueilLargeState();
}

class _DiscusuraccueilLargeState extends State<DiscusuraccueilLarge>
    with AutomaticKeepAliveClientMixin<DiscusuraccueilLarge> {
  @override
  bool get wantKeepAlive => true;

  late Future<List<Map<String, dynamic>>> _discussionsFuture;
  Map<String, dynamic>? _selectedDiscussion;

  @override
  void initState() {
    super.initState();
    _loadDiscussions();
  }

  void _loadDiscussions() {
    print("[LOG] Chargement des discussions client...");
    _discussionsFuture = Provider.of<MessageProvider>(
      context,
      listen: false,
    ).getClientProductsWithMessages();
  }

  Future<void> _refreshDiscussions() async {
    print("[LOG] Rafraîchissement manuel des discussions client.");
    setState(() {
      _loadDiscussions();
      _selectedDiscussion = null;
    });
  }

  void _selectDiscussion(Map<String, dynamic> discussion) {
    setState(() {
      _selectedDiscussion = discussion;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFFDF6F0), // Blanc crème
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFFFDF6F0), // Blanc crème
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 25.0),
                          child: Text(
                            'Mes Discussions',
                            style: TextStyle(
                              color: Color(0xFF2C3E50), // Gris foncé pour contraste
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _refreshDiscussions,
                      icon: Icon(
                        FluentIcons.arrow_sync_20_regular,
                        color: Styles.rouge,
                      ),
                      tooltip: 'Actualiser',
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Vos conversations avec les vendeurs',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: RefreshIndicator(
          onRefresh: _refreshDiscussions,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _discussionsFuture,
            builder: (context, snapshot) {
              print("[LOG] FutureBuilder state: ${snapshot.connectionState}");
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                print("[LOG] Erreur du FutureBuilder: ${snapshot.error}");
                return Center(child: Text("Erreur: ${snapshot.error}"));
              }
              final discussions = snapshot.data ?? [];
              print("[LOG] Discussions client trouvées: ${discussions.length}");

              if (discussions.isEmpty) {
                return _buildEmptyState();
              }

              // Auto-sélectionner la première discussion si aucune n'est sélectionnée
              if (_selectedDiscussion == null && discussions.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _selectDiscussion(discussions.first);
                });
              }

              return Row(
                children: [
                  // Panneau gauche : Liste des discussions
                  SizedBox(
                    width: 400, // Largeur fixe pour le panneau gauche
                    child: _buildDiscussionsList(discussions),
                  ),
                  // Séparateur vertical
                  Container(
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  // Panneau droit : Chat intégré
                  Expanded(
                    child: _selectedDiscussion != null
                        ? _buildDiscussionContent()
                        : Container(
                            color: Colors.grey.shade50,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.chat_multiple_24_regular,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune discussion en cours',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vos conversations apparaîtront ici.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionsList(List<Map<String, dynamic>> discussions) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Icon(FluentIcons.chat_multiple_24_regular, color: Styles.rouge),
                const SizedBox(width: 12),
                const Text(
                  'Discussions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: discussions.length,
              itemBuilder: (context, index) {
                return _buildDiscussionListItem(discussions[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionListItem(Map<String, dynamic> discussion) {
    final isSelected = _selectedDiscussion?['idproduit'] == discussion['idproduit'];
    final lastMessageDate = DateTime.parse(discussion['lastMessageDate']);
    final formattedDate = DateFormat('dd/MM/yyyy à HH:mm').format(lastMessageDate);

    return Card(
      color: isSelected ? Styles.rouge.withOpacity(0.05) : Styles.blanc,
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Styles.rouge.withOpacity(0.3) : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectDiscussion(discussion),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            discussion['nomproduit'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Styles.rouge : Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: Icon(
                              FluentIcons.checkmark_circle_24_regular,
                              color: Styles.rouge,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${discussion['idproduit']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          FluentIcons.chat_multiple_20_regular,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${discussion['messageCount']} message(s)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          FluentIcons.clock_20_regular,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isSelected ? Styles.rouge : Colors.grey.shade500,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscussionContent() {
    if (_selectedDiscussion == null) {
      return Container(
        color: Colors.grey.shade50,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Utilise la classe ChatPageWithArgs du dashboard commercial
    final key = ValueKey('${_selectedDiscussion!['idproduit']}_${DateTime.now().millisecondsSinceEpoch}');

    return ChatPageWithArgs(
      key: key, // Force recreation when discussion changes
      arguments: {
        'idproduit': _selectedDiscussion!['idproduit'],
        'nomproduit': _selectedDiscussion!['nomproduit'],
        'isCommercial': false, // Important : client = false
      },
    );
  }
}
