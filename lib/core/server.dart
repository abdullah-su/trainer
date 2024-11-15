import 'dart:convert';
import 'dart:io';
import 'deck.dart';

var deck;
var card;
late final String file, path;

Future<void> main(List<String> args) async {
  switch(args.length){
    case 0:
      stdout.writeln('No file specified');
      return;
    case 1:
      file = args[0];
      path = '';
    case 2:
      file = args[0];
      path = args[1];
    default:
      stdout.writeln('Too many arguments');
      return;
  }
  deck = Deck(file);
  deck.goto(path);
  deck.loadTimes('$file.pgs');
  deck.direction = 'native';
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('Server running on http://${server.address.host}:${server.port}');

  await for (HttpRequest request in server) {
    // Добавляем заголовки CORS
    request.response.headers.add("Access-Control-Allow-Origin", "*"); // Разрешить всем источникам доступ
    request.response.headers.add("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
    request.response.headers.add("Access-Control-Allow-Headers", "Content-Type");
    if (request.method == 'OPTIONS') {
      request.response
        ..statusCode = HttpStatus.ok
        ..close();
      continue;
    }
    print("\nЗапрос: ${request.method}: ${request.uri}");

    if (request.uri.path == '/get-card') {
      _handleGetCard(request);
    } else if (request.uri.path == '/answer' && request.method == 'POST') {
      await _handleAnswer(request);
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Not Found')
        ..close();
    }
  }
}

void _handleGetCard(HttpRequest request) {
  // Получаем значение параметра direction из запроса
  String? direction = request.uri.queryParameters['direction'];
  deck.direction = direction ?? 'native';
  card = deck.getCard();
  var front, back;
  if (direction == 'native') {
    front = card.native;
    back = card.foreign;
  } else {
    front = card.foreign;
    back = card.native;
  }
  final response = {
    'id': card.id,
    'front': front,
    'back': back,
    'date': DateTime.now().millisecondsSinceEpoch,
    'stat': {
      'new': deck.sumNew,
      'current': deck.sumCur,
      'next': deck.sumNext,
      'end': deck.sumEnd,
    },
    'fromList': deck.fromList,
  };
  print('Ответ:');
  print('id: ${response['id']}');
  print('date: ${response['date']} (${toDurationString(response['date'])})');
  print('stat: ${response['stat']}');
  request.response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(response))
    ..close();
}

Future<void> _handleAnswer(HttpRequest request) async {
  var content = await utf8.decoder.bind(request).join();
  var data = jsonDecode(content) as Map<String, dynamic>;
  double answer = double.parse(data['answer'] ?? '1.0');
  print('Ответ: $answer');

  deck.fixReverse();
  print('-Было:  ${toDurationString(card.duration)} (${card.duration}) / ${toDurationString(card.durationR)} (${card.durationR})');
  int newDuration = deck.calculateDuration(card, answer);
  print(newDuration);
  deck.recalculateCard(card, newDuration, answer);
  print('-Стало:  ${toDurationString(card.duration)} (${card.duration}) / ${toDurationString(card.durationR)} (${card.durationR})');
  deck.saveTimes("$file.pgs");

  var response = {
    'duration': card.duration,
    'durationReverse': card.durationR,
  };

  request.response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(response))
    ..close();
}

String toDual(int num) => (num < 10) ? '0$num' : '$num';

String toDurationString(int d) {
  if (d > -1) {
    int days = d ~/ 1000 ~/ 60 ~/ 60 ~/ 24;
    d -= days * 24 * 60 * 60 * 1000;
    int hours = d ~/ 1000 ~/ 60 ~/ 60;
    d -= hours * 60 * 60 * 1000;
    int minutes = d ~/ 1000 ~/ 60;
    d -= minutes * 60 * 1000;
    int seconds = d ~/ 1000;
    return '$days.$hours:${toDual(minutes)}:${toDual(seconds)}';
  }
  return 'новая';
}
