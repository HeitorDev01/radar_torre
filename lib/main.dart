import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

// ===== AJUSTE AQUI =====
const porta = 'COM5';             // a mesma da IDE
const double alcanceMax = 15;    // cm que o radar mostra
// =======================

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TelaRadar(),
    ));

class TelaRadar extends StatefulWidget {
  const TelaRadar({super.key});
  @override
  State<TelaRadar> createState() => _TelaRadarState();
}

class _TelaRadarState extends State<TelaRadar> {
  SerialPort? _port;
  SerialPortReader? _reader;
  String _buffer = '';
  int _anguloAtual = 0;
  final Map<int, double> _dist = {};       // distância por ângulo
  final Map<int, DateTime> _quando = {};   // quando foi visto (pra sumir)
  String? _erro;

  @override
  void initState() {
    super.initState();
    _conectar();
  }

  void _conectar() {
    try {
      final p = SerialPort(porta);
      if (!p.openRead()) {
        setState(() => _erro =
            'Não consegui abrir a $porta.\nFeche o Serial Monitor da IDE.');
        return;
      }
      p.config = SerialPortConfig()
        ..baudRate = 9600
        ..bits = 8
        ..stopBits = 1
        ..parity = SerialPortParity.none;
      _port = p;
      _reader = SerialPortReader(p);
      _reader!.stream.listen(_receber);
    } catch (e) {
      setState(() => _erro = 'Erro: $e');
    }
  }

  void _receber(Uint8List dados) {
    _buffer += utf8.decode(dados, allowMalformed: true);
    final linhas = _buffer.split('\n');
    _buffer = linhas.removeLast();
    for (final l in linhas) {
      final partes = l.trim().split(',');
      if (partes.length != 2) continue;
      final ang = int.tryParse(partes[0]);
      final d = double.tryParse(partes[1]);
      if (ang == null || d == null) continue;
      setState(() {
        _anguloAtual = ang;
        if (d > 0 && d <= alcanceMax) {
          _dist[ang] = d;
          _quando[ang] = DateTime.now();
        } else {
          _dist.remove(ang);
        }
      });
    }
  }

  @override
  void dispose() {
    _reader?.close();
    _port?.close();
    _port?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _erro != null
            ? Text(_erro!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 18))
            : Padding(
                padding: const EdgeInsets.all(24),
                child: AspectRatio(
                  aspectRatio: 2, // semicírculo
                  child: CustomPaint(
                    painter: RadarPainter(_anguloAtual, _dist, _quando),
                  ),
                ),
              ),
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final int angulo;
  final Map<int, double> dist;
  final Map<int, DateTime> quando;
  RadarPainter(this.angulo, this.dist, this.quando);

  static const verde = Color(0xFF00FF66);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final raio = size.width / 2 * 0.95;

    // arcos de distância
    final arco = Paint()
      ..color = verde.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (int i = 1; i <= 4; i++) {
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: raio * i / 4),
          pi, pi, false, arco);
    }

    // linhas de ângulo
    final linha = Paint()
      ..color = verde.withOpacity(0.2)
      ..strokeWidth = 1;
    for (int a = 0; a <= 180; a += 30) {
      final rad = pi - a * pi / 180;
      canvas.drawLine(
          center, center + Offset(raio * cos(rad), -raio * sin(rad)), linha);
    }

    // feixe varrendo
    final rad = pi - angulo * pi / 180;
    canvas.drawLine(
        center,
        center + Offset(raio * cos(rad), -raio * sin(rad)),
        Paint()
          ..color = verde
          ..strokeWidth = 2);

       // só o alvo mais próximo
    final agora = DateTime.now();
    int? alvoAng;
    double menorDist = double.infinity;
    dist.forEach((a, d) {
      final t = quando[a];
      if (t == null) return;
      if (agora.difference(t).inMilliseconds > 2000) return; // some depois de 2s
      if (d < menorDist) {
        menorDist = d;
        alvoAng = a;
      }
    });

    if (alvoAng != null) {
      final r = pi - alvoAng! * pi / 180;
      final rr = raio * (menorDist / alcanceMax).clamp(0.0, 1.0);
      final p = center + Offset(rr * cos(r), -rr * sin(r));
      // ponto vermelho
      canvas.drawCircle(p, 8, Paint()..color = const Color(0xFFFF3B30));
      // anel de alerta em volta
      canvas.drawCircle(
          p,
          16,
          Paint()
            ..color = const Color(0x66FF3B30)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant RadarPainter old) => true;
}