import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:yuugao/providers/user_provider.dart';
import 'package:yuugao/theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 登录成功后由 _AuthGate 自动切换，这里仅监听报错
    ref.listen(userProvider.select((s) => s.status), (prev, next) {
      if (next == AuthStatus.authenticated && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              'yuugao',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '网易云音乐',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            TabBar(
              controller: _tab,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: '手机号登录'),
                Tab(text: '扫码登录'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [_PhoneLoginTab(), _QrLoginTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneLoginTab extends ConsumerStatefulWidget {
  const _PhoneLoginTab();

  @override
  ConsumerState<_PhoneLoginTab> createState() => _PhoneLoginTabState();
}

class _PhoneLoginTabState extends ConsumerState<_PhoneLoginTab> {
  final _phone = TextEditingController();
  final _secret = TextEditingController();
  bool _useCaptcha = false;
  bool _loading = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _phone.dispose();
    _secret.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_phone.text.trim().isEmpty) {
      _toast('请输入手机号');
      return;
    }
    final ok = await ref
        .read(userProvider.notifier)
        .sendSmsCode(_phone.text.trim());
    if (!mounted) return;
    if (ok) {
      setState(() => _countdown = 60);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_countdown <= 1) {
          t.cancel();
          if (mounted) setState(() => _countdown = 0);
        } else {
          if (mounted) setState(() => _countdown--);
        }
      });
    } else {
      _toast('验证码发送失败');
    }
  }

  Future<void> _login() async {
    final phone = _phone.text.trim();
    final secret = _secret.text.trim();
    if (phone.isEmpty || secret.isEmpty) {
      _toast('请填写完整');
      return;
    }
    setState(() => _loading = true);
    final notifier = ref.read(userProvider.notifier);
    final ok = await notifier.loginByPhone(
      phone: phone,
      password: _useCaptcha ? null : secret,
      captcha: _useCaptcha ? secret : null,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) {
      _toast(ref.read(userProvider).error ?? '登录失败');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: '手机号',
              prefixIcon: Icon(Icons.phone_android),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _secret,
            obscureText: !_useCaptcha,
            decoration: InputDecoration(
              labelText: _useCaptcha ? '验证码' : '密码',
              prefixIcon: Icon(_useCaptcha ? Icons.sms : Icons.lock),
              suffixIcon: _useCaptcha
                  ? TextButton(
                      onPressed: _countdown > 0 ? null : _sendCode,
                      child: Text(_countdown > 0 ? '${_countdown}s' : '获取验证码'),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _useCaptcha = !_useCaptcha),
              child: Text(_useCaptcha ? '改用密码登录' : '改用验证码登录'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('登录'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrLoginTab extends ConsumerStatefulWidget {
  const _QrLoginTab();

  @override
  ConsumerState<_QrLoginTab> createState() => _QrLoginTabState();
}

class _QrLoginTabState extends ConsumerState<_QrLoginTab> {
  String? _qrUrl;
  String? _key;
  String _hint = '正在生成二维码…';
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _genQr();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _genQr() async {
    _poll?.cancel();
    setState(() {
      _qrUrl = null;
      _hint = '正在生成二维码…';
    });
    final res = await ref.read(userProvider.notifier).createQr();
    if (!mounted) return;
    if (res == null) {
      setState(() => _hint = '生成失败，点击重试');
      return;
    }
    setState(() {
      _key = res.key;
      _qrUrl = res.qrUrl;
      _hint = '请用网易云音乐 App 扫码';
    });
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _check());
  }

  Future<void> _check() async {
    final key = _key;
    if (key == null) return;
    final code = await ref.read(userProvider.notifier).pollQr(key);
    if (!mounted) return;
    switch (code) {
      case 800:
        _poll?.cancel();
        setState(() => _hint = '二维码已过期，点击刷新');
        break;
      case 801:
        setState(() => _hint = '请用网易云音乐 App 扫码');
        break;
      case 802:
        setState(() => _hint = '已扫描，请在手机上确认');
        break;
      case 803:
        _poll?.cancel();
        setState(() => _hint = '登录成功');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: (_qrUrl == null) ? _genQr : null,
            child: Container(
              width: 220,
              height: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _qrUrl == null
                  ? const Center(child: CircularProgressIndicator())
                  : QrImageView(data: _qrUrl!, version: QrVersions.auto),
            ),
          ),
          const SizedBox(height: 20),
          Text(_hint, style: const TextStyle(color: AppColors.textSecondary)),
          TextButton(onPressed: _genQr, child: const Text('刷新二维码')),
        ],
      ),
    );
  }
}
