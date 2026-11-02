# 🎯 Radar Torre

Radar de varredura com sensor ultrassônico e **Arduino Uno**, com uma tela de radar em tempo real feita em **Flutter**. Um servo gira o sensor varrendo o ambiente, e os objetos detectados aparecem na tela como alvos, no estilo de um radar.

Primeira etapa de um projeto maior: uma "torre sentinela" que detecta movimento. A evolução planejada é uma versão com **câmera + visão computacional** (ver [Próximos passos](#-próximos-passos)).

---

## 📋 Como funciona

O sensor **HC-SR04** funciona como um morcego: dispara um "ping" de som inaudível, o som bate no objeto e volta, e o sensor mede **quanto tempo** levou para retornar. Com esse tempo, o Arduino calcula a **distância** do objeto. Girando o sensor com um servo, ele "varre" o ambiente e sabe a que distância está cada coisa em cada ângulo — exatamente o princípio de um radar.

---

## 🧰 Componentes

- Arduino Uno
- Sensor ultrassônico HC-SR04
- Servo motor 9g
- Protoboard
- LED + resistor de 220 Ω (alerta)
- Buzzer ativo (alarme)
- Jumpers

---

## 🔌 Ligações

| Componente | Pino do Arduino |
|---|---|
| Servo (sinal) | 11 |
| HC-SR04 — Trig | 9 |
| HC-SR04 — Echo | 10 |
| HC-SR04 — VCC | 5V |
| HC-SR04 — GND | GND |
| LED (com resistor) | 7 |
| Buzzer (+) | 8 |

> O HC-SR04 usa **5V** (diferente de módulos como o RFID, que usam 3.3V).

---

## 💻 Código do Arduino

Varre um leque de 90° (centrado para frente), envia `ângulo,distância` para o app e dispara LED + buzzer quando algo entra na zona.

```cpp
#include <Servo.h>

Servo radar;
int trig = 9;
int echo = 10;
int led = 7;
int buzzer = 8;
int alcanceMax = 100;   // cm para disparar o alarme

void setup() {
  Serial.begin(9600);
  radar.attach(11);
  pinMode(trig, OUTPUT);
  pinMode(echo, INPUT);
  pinMode(led, OUTPUT);
  pinMode(buzzer, OUTPUT);
}

long medirDistancia() {
  digitalWrite(trig, LOW);
  delayMicroseconds(2);
  digitalWrite(trig, HIGH);
  delayMicroseconds(10);
  digitalWrite(trig, LOW);
  long tempo = pulseIn(echo, HIGH, 30000);
  if (tempo == 0) return 0;
  return tempo * 0.034 / 2;
}

void varrer(int inicio, int fim, int passo) {
  for (int ang = inicio; ang != fim; ang += passo) {
    radar.write(ang);
    delay(30);
    long d = medirDistancia();

    // envia para o app (radar na tela)
    Serial.print(ang);
    Serial.print(",");
    Serial.println(d);

    // alarme
    if (d > 0 && d <= alcanceMax) {
      digitalWrite(led, HIGH);
      digitalWrite(buzzer, HIGH);
    } else {
      digitalWrite(led, LOW);
      digitalWrite(buzzer, LOW);
    }
  }
}

void loop() {
  varrer(45, 135, 2);   // leque de 90° centrado para frente
  varrer(135, 45, -2);
}
```

### Ajustes rápidos

- **Leque de varredura:** mexa nos números do `loop`. Regra: centro 90 ± metade do leque. Ex.: 90° → `45` e `135`; 45° → `68` e `112`.
- **Alcance do alarme:** mude o `alcanceMax` (em cm).

---

## 📱 Aplicativo (Flutter)

Tela de radar desktop (Windows) que lê os dados do Arduino pela USB e desenha o radar em tempo real: o feixe varrendo e o alvo mais próximo marcado em vermelho.

- **Stack:** Flutter / Dart
- **Pacote:** [`flutter_libserialport`](https://pub.dev/packages/flutter_libserialport)
- **Desenho:** `CustomPainter` (radar, arcos de distância, feixe e alvo desenhados à mão no canvas)
- Ajuste no topo do `lib/main.dart`: `porta` (ex.: `COM5`) e `alcanceMax` (distância que o radar mostra — quanto menor, mais "perto" ele foca).

**Rodar:**
```bash
flutter pub get
flutter run -d windows
```

> Feche o Serial Monitor da Arduino IDE antes de rodar o app — só um programa por vez pode usar a porta COM.

---

## 🔭 Próximos passos

- [ ] Fechar o desenho do radar para o mesmo ângulo da varredura
- [ ] Torre física: base giratória com motor de passo (360°) + estrutura impressa em 3D
- [ ] **Versão "anti-aérea" com câmera:** rastreamento de alvo por webcam usando visão computacional (Python + OpenCV), com a mira acompanhando o alvo na tela

> 🔒 **Nota de segurança:** qualquer versão com disparo usa apenas projéteis leves e inofensivos (espuma, bolinha), em alvos de treino — nunca apontado para pessoas.

---

## 👤 Autor

**Heitor Carvalho** — [GitHub](https://github.com/HeitorDev01)