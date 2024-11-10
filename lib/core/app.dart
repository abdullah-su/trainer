import 'deck.dart';
import 'dart:io';

void main(List<String> args) {
  
  final String file, path;
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
  
  stdout.writeln("Ас-саляяму 'алейкум! Сегодня: ${DateTime.now().millisecondsSinceEpoch}");
  // stdout.writeln("Айда изучим '$path' ветку из базы '$file'.\n");

  var deck = Deck(file);
  deck.goto(path);
  deck.loadTimes('$file.pgs');
  deck.direction = 'native';
  // stdout.writeln('Количество всего: ${deck.all.length}');
  // stdout.writeln('Количество в ветке: ${deck.list.length}');

  while (true) {
    cleanScreen();
    var card = deck.getCard();
    stdout.writeln("Ас-саляяму 'алейкум! Сегодня: ${DateTime.now().millisecondsSinceEpoch}");
    stdout.writeln('нов: ${deck.sumNew} тек: ${deck.sumCur} буд: ${deck.sumNext} завер: ${deck.sumEnd}\n');
    stdout.writeln("${card.id}\n");
    // deal card
    stdout.writeln(card.native);
    var key = stdin.readLineSync();
    if (key == 'q') return;
    // reverse
    deck.fixReverse();
    stdout.writeln('${card.foreign}\n');
    // get answer
    var answer = stdin.readLineSync();
    if (key == 'q') return;
    // results
    stdout.writeln('${card.time} ${toDurationString(card.duration)} ${card.timeR} ${toDurationString(card.durationR)}');
    deck.recalculate(card, deck.calculateCard(card, int.parse(answer ?? '5') / 5));
    stdout.writeln('${card.time} ${toDurationString(card.duration)} ${card.timeR} ${toDurationString(card.durationR)}');
    key = stdin.readLineSync(); // pause
    if (key == 'q') return;
    deck.saveTimes('$file.pgs'); // save progress
  }
}
// 	# Если изменился текст
// 		R.deck.edit(R.card, R.textTop.text, R.textBottom.text)
// 		sendToServer(R.card)
	
// ################################ СЕТЬ ##############################################################

// func _on_loader_request_completed(result, response_code, headers, body):
// 	if result == HTTPRequest.RESULT_SUCCESS:
// 		if response_code == 200:
// 			var file = FileAccess.open('user://bayna.csv', FileAccess.WRITE)
// 			file.store_string(body.get_string_from_utf8())
// 			file = null
// 			get_tree().reload_current_scene()

// func sendToServer(c):
// 	var http_client = HTTPClient.new()
// 	var fields = {"client" : OS.get_unique_id(), "path" : c.id, "native" : c.native, "foreign": c.foreign, "secret": "gfhjkm"}
// 	var query = http_client.query_string_from_dict(fields)
// 	var headers = ["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(query.length())]
// 	$saver.request("https://apps.abdullah.su/api/trainer.php?", headers, HTTPClient.METHOD_POST, query)

// func _on_http_request_request_completed(result, response_code, headers, body):
// 	if result == HTTPRequest.RESULT_SUCCESS:
// 		if response_code == 200:
// 			print(body.get_string_from_utf8())
// 		else:
// 			print("HTTP Error")

String toDual(int num) => (num < 10) ? '0$num' : '$num';

String toDurationString(int d) {
	if (d > -1) {
		int days = d ~/ 1000 ~/ 60 ~/ 60 ~/ 24;
		d -= days * 24 * 60 * 60 * 1000;
		int hours = d ~/ 1000 ~/ 60 ~/ 60;
		d -= hours * 60 * 60 * 1000;
		int minutes = d ~/ 1000~/ 60;
		d -= minutes * 60 * 1000;
		int seconds = d ~/ 1000;
		d -= seconds * 1000;
		int millseconds = d;
		return '$days.$hours:${toDual(minutes)}:${toDual(seconds)}';
  }
  return 'новая';
}

void cleanScreen() {
  stdout.write('\x1B[2J\x1B[;H');
}