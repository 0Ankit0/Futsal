import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/dimension.dart';
import 'data/model/loyalty_model.dart';
import 'data/repository/loyalty_repository.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  final _repo = LoyaltyRepository();
  LoyaltyAccount? _account;
  List<LoyaltyTransaction> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final account = await _repo.getAccount();
      final history = await _repo.getHistory();
      if (mounted) {
        setState(() {
          _account = account;
          _history = history;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Dimension.init(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Loyalty Points',
          style: TextStyle(
            fontSize: Dimension.font(20),
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(Dimension.width(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAccountCard(),
                        SizedBox(height: Dimension.height(24)),
                        _buildHistorySection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: Dimension.width(64), color: Colors.red),
          SizedBox(height: Dimension.height(16)),
          Text(_error!, textAlign: TextAlign.center),
          SizedBox(height: Dimension.height(16)),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard() {
    final account = _account!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Dimension.width(20)),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(Dimension.width(16)),
        boxShadow: [AppTheme.buttonShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars, color: Colors.white, size: Dimension.width(28)),
              SizedBox(width: Dimension.width(8)),
              Text(
                'Your Points',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: Dimension.font(14),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: Dimension.height(12)),
          Text(
            '${account.pointsBalance}',
            style: TextStyle(
              color: Colors.white,
              fontSize: Dimension.font(48),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: Dimension.height(16)),
          Row(
            children: [
              _buildStatChip(
                label: 'Total Earned',
                value: '${account.totalEarned}',
              ),
              SizedBox(width: Dimension.width(12)),
              _buildStatChip(
                label: 'Total Redeemed',
                value: '${account.totalRedeemed}',
              ),
            ],
          ),
          SizedBox(height: Dimension.height(8)),
          Text(
            'Earn points on every booking. Redeem at checkout!',
            style: TextStyle(
              color: Colors.white60,
              fontSize: Dimension.font(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({required String label, required String value}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimension.width(12),
        vertical: Dimension.height(6),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(Dimension.width(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: Dimension.font(11),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: Dimension.font(16),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction History',
          style: TextStyle(
            fontSize: Dimension.font(18),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: Dimension.height(12)),
        if (_history.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: Dimension.height(32)),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: Dimension.width(56),
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: Dimension.height(12)),
                  Text(
                    'No transactions yet',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: Dimension.font(14),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _history.length,
            separatorBuilder: (_, __) => SizedBox(height: Dimension.height(8)),
            itemBuilder: (context, index) {
              final tx = _history[index];
              final isEarned = tx.transactionType == 'earned';
              return Container(
                padding: EdgeInsets.all(Dimension.width(16)),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimension.width(12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: Dimension.width(40),
                      height: Dimension.width(40),
                      decoration: BoxDecoration(
                        color: (isEarned ? Colors.green : Colors.orange)
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEarned ? Icons.add_circle : Icons.remove_circle,
                        color: isEarned ? Colors.green : Colors.orange,
                        size: Dimension.width(22),
                      ),
                    ),
                    SizedBox(width: Dimension.width(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.description,
                            style: TextStyle(
                              fontSize: Dimension.font(14),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            isEarned ? 'Earned' : 'Redeemed',
                            style: TextStyle(
                              fontSize: Dimension.font(12),
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isEarned ? '+' : '-'}${tx.points} pts',
                      style: TextStyle(
                        fontSize: Dimension.font(16),
                        fontWeight: FontWeight.w700,
                        color: isEarned ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
