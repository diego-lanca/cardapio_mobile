import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Título
          const Text(
            'Sobre o aplicativo',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),

          // 🔹 Objetivo
          _AboutCard(
            title: 'Objetivo',
            child: const Text(
              'Este aplicativo tem como objetivo facilitar o processo de pedidos '
              'em uma rotisseria, permitindo ao usuário visualizar o cardápio, '
              'adicionar itens ao carrinho e realizar pedidos de forma prática e rápida.',
              style: TextStyle(height: 1.4),
            ),
          ),

          const SizedBox(height: 16),

          // 🔹 Equipe
          _AboutCard(
            title: 'Equipe de desenvolvimento',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _MemberTile(
                  name: 'Diego Lança de Oliveira',
                  code: '837756',
                ),
                _MemberTile(
                  name: 'Otávio Ribeiro',
                  code: '838807',
                ),
                _MemberTile(
                  name: 'Vitor Ferraz Marini',
                  code: '837771',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 🔹 Informações acadêmicas
          _AboutCard(
            title: 'Informações acadêmicas',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _InfoRow(label: 'Curso', value: 'Engenharia da Computação'),
                _InfoRow(label: 'Instituição', value: 'UNAERP'),
                _InfoRow(label: 'Professor', value: 'Rodrigo Plotze'),
                _InfoRow(label: 'Disciplina', value: 'Desenvolvimento Mobile'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 🔹 Versão
          _AboutCard(
            title: 'Aplicativo',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _InfoRow(label: 'Versão', value: '1.0.0'),
                _InfoRow(label: 'Build', value: '2026.04'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _AboutCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final String name;
  final String code;

  const _MemberTile({
    required this.name,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.person_outline,
            size: 18,
            color: Color(0xFFE53935),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            code,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}