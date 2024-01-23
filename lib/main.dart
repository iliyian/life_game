import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(body: LifeGame()),
      title: "Life Game",
      theme: ThemeData(
        fontFamily: "Mi Sans",
      ),
    ),
  );
}

class LifeGame extends StatefulWidget {
  const LifeGame({super.key});

  @override
  State<StatefulWidget> createState() => LifeGameState();
}

class Life {
  late int x, y;
  late bool col;
  Life(this.x, this.y, this.col);
}

class LifeGameState extends State<LifeGame> {
  late List<List<bool>> data;
  Random random = Random();

  int len = 120, siz = 5;
  final int fps = 25;
  late int screenWidth, screenHeight;

  final List<int> dx = [-1, -1, 0, 1, 1, 1, 0, -1];
  final List<int> dy = [0, 1, 1, 1, 0, -1, -1, -1];

  late Timer timer;
  bool isRunning = false, isDrawing = false;

  void generate(bool Function(int idx) genFunction) {
    setState(() {
      data = List.generate(
          len, (i) => List.generate(len, (j) => genFunction(i * len + j)),
          growable: false);
    });
  }

  void revoke() {
    setState(() {
      generate((idx) => random.nextBool());
    });
  }

  void checkRatio() {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    screenWidth = mediaQueryData.size.width.round();
    screenHeight = mediaQueryData.size.height.round();

    if (screenWidth < screenHeight && screenWidth <= len * siz) {
      setState(() {
        siz = (screenWidth * 0.8 / len).round();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    revoke();
  }

  void evolve() {
    setState(() {
      List<List<bool>> newData = List.generate(
          len, (i) => List.generate(len, (j) => false, growable: false),
          growable: false);
      // print(data);
      for (int x = 0; x < len; x++) {
        for (int y = 0; y < len; y++) {
          int sum = 0;
          for (int i = 0; i < 8; i++) {
            int xx = dx[i] + x, yy = y + dy[i];
            if (xx < 0 || xx >= len || yy < 0 || yy >= len) continue;
            sum += data[xx][yy] ? 1 : 0;
          }
          if (sum == 3) {
            newData[x][y] = true;
          } else if (sum == 2) {
            newData[x][y] = data[x][y];
          } else {
            newData[x][y] = false;
          }
        }
      }
      for (int x = 0; x < len; x++) {
        for (int y = 0; y < len; y++) {
          data[x][y] = newData[x][y];
        }
      }
    });
  }

  void run() {
    setState(() {
      if (isRunning) return;
      isRunning = true;
      timer =
          Timer.periodic(Duration(milliseconds: (1000 / fps).round()), (timer) {
        evolve();
      });
    });
  }

  void stop() {
    setState(() {
      if (!isRunning) return;
      isRunning = false;
      timer.cancel();
    });
  }

  void draw(DragUpdateDetails details) {
    if (!isDrawing) return;
    setState(() {
      var position = details.localPosition;
      double x = position.dx, y = position.dy;
      int xi = (x / siz).round(), yi = (y / siz).round();
      if (xi < 0 || xi >= len || yi < 0 || yi >= len) return;
      data[xi][yi] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // print(data);
    checkRatio();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
            child: CustomPaint(
          painter: LifeGamePainter(
            data,
            len,
            siz,
          ),
          child: GestureDetector(
            onPanUpdate: draw,
            child: Container(
              width: siz * len.toDouble(),
              height: siz * len.toDouble(),
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.black)),
            ),
          ),
        )),
        SizedBox(
          width: (len * siz).toDouble(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: ElevatedButton(onPressed: run, child: Text("运行")),
              ),
              Expanded(
                flex: 1,
                child: ElevatedButton(onPressed: stop, child: Text("暂停")),
              ),
              Expanded(
                flex: 1,
                child: ElevatedButton(onPressed: evolve, child: Text("单步")),
              ),
            ],
          ),
        ),
        SizedBox(
          width: (len * siz).toDouble(),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Expanded(
                child: ElevatedButton(onPressed: revoke, child: Text("随机"))),
            Expanded(
              child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isDrawing = !isDrawing;
                    });
                  },
                  child: Text(isDrawing ? "作画中" : "作画")),
            ),
            Expanded(
              child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      generate((idx) => false);
                    });
                  },
                  child: Text("清空")),
            )
          ]),
        ),
      ],
    );
  }
}

class LifeGamePainter extends CustomPainter {
  final List<List<bool>> data;
  final int len, siz;

  LifeGamePainter(this.data, this.len, this.siz);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();

    for (int x = 0; x < len; x++) {
      for (int y = 0; y < len; y++) {
        paint.color = data[x][y] == true ? Colors.black : Colors.white;
        // print("${x} ${y} ${paint.color} ${data[x][y]}");
        canvas.drawRect(
            Rect.fromLTWH(x * siz.toDouble(), y * siz.toDouble(),
                siz.toDouble(), siz.toDouble()),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
