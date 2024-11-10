import 'dart:io';
import 'dart:math';
import 'card.dart';
class Deck {
  List<Card> all = [];
  List<Card> list = [];
  List<Card> currentList = [];
  List<Card> nextList = [];
  int maxLevel = 16; // 16 = около 3 месяцев
  int maxDuration = (exp(16) * 1000).round();
  int sumCur = 0;
  int sumNext = 0;
  int sumNew = 0;
  int sumEnd = 0;
  String fromList = 'darkgreen';
  String direction = 'native';

  late int dealTime; 		// время раздачи
  late int reverseTime;  		// время переворота

  Deck(String filepath) {
    loadDeck(filepath);
  }

void listsPrepare() {
  	dealTime = DateTime.now().millisecondsSinceEpoch;
  	currentList = [];
  	nextList = [];
  	sumCur = 0;
  	sumNext = 0;
  	sumNew = 0;
    sumEnd = 0;
	if (direction == 'native'){ // если направление Прямое
    for (Card c in list) {
      // вычищаем от выученных карточек
      if (c.duration > maxDuration) {
        sumEnd += 1; // считаем изученые / удалённые
        continue;
      }
      // разделяем на два списка Текущих и Будущих карточек
      if (c.time <= dealTime) {
        currentList.add(c);
        sumCur += 1; // считаем текущие
      } else {
        nextList.add(c);
        if (c.duration == -1) {
          sumNew += 1; // считаем новые
        } else {
          sumNext += 1; // считаем следующие
        }
      }
    }
    // и сортируем эти 2 списка
    currentList.sort((b, a) => a.time.compareTo(b.time));
    nextList.sort((a, b) => a.time.compareTo(b.time));
  } else { // если направление Обратное
    for (Card c in list) {
      // вычищаем от вычеркнутых или выученных карточек
      if (c.durationR > maxDuration) {
        sumEnd += 1; // считаем изученые / удалённые
        continue;
      }
      // разделяем на два списка Текущих и Будущих карточек
      if (c.timeR <= dealTime) {
        currentList.add(c);
        sumCur += 1; // считаем текущие
      } else {
        nextList.add(c);
        if (c.durationR == -1) {
          sumNew += 1; // считаем новые
        } else {
          sumNext += 1; // считаем следующие
        }
      }
    }
    // и сортируем эти 2 списка
    currentList.sort((b, a) => a.timeR.compareTo(b.timeR));
    nextList.sort((a, b) => a.timeR.compareTo(b.timeR));
  }
}
void loadDeck(filepath){
	all = [];
	var rows = fileToArray(filepath);
  for (var row in rows) {
    all.add(Card(id: row[0], native: row[1], foreign: row[2]));
  }
}

void goto(String path) {
  list = [];
  for (var card in all) {
    if (card.id.startsWith(path)) {
      list.add(card);
    }
  }
}

// void loadTimes_old(String filepath) {
//   List<List<String>> rows = fileToArray(filepath);
//   for (List<String> row in rows) {
//     for (var card in list) {
//       if (card.id == row[0]) { /////////////////////////// *1000 убрать после
//         card.time = (double.parse(row[1]) * 1000).round();
//         card.duration = (double.parse(row[2]) * 1000).round();
//         card.timeR = (double.parse(row[3]) * 1000).round();
//         card.durationR = (double.parse(row[4]) * 1000).round();
//         break;
//       }
//     }
//   }
// }

void loadTimes(String filepath) {
  List<List<String>> rows = fileToArray(filepath);
  for (List<String> row in rows) {
    for (var card in list) {
      if (card.id == row[0]) {
        card.time = int.parse(row[1]);
        card.duration = int.parse(row[2]);
        card.timeR = int.parse(row[3]);
        card.durationR = int.parse(row[4]);
        break;
      }
    }
  }
}

Card getCard() {
  Card emptyCard = Card(id: 'err', native: 'ВСЁ ИЗУЧЕНО', foreign: '-');
  listsPrepare();
	if (direction == 'native'){ // если направление Прямое

    // изучаем в первую очередь всё из Текущего списка
    if (currentList.length != 0) {
      fromList = 'darkblue';
      return currentList[0];
    } // а после из Следующего
    else {
      for (Card nextCard in nextList) {
        if (nextCard.duration < 0) {
          fromList = 'darkgreen';
          return nextCard;
        }
      }
      if (nextList.length != 0) {
        fromList = 'darkred';
        return nextList[0];
      } else {
        fromList = 'black';
        return emptyCard; // ВСЁ ИЗУЧЕНО
      }
    }
  } else { // если направление Обратное
    if (currentList.length != 0) {
      return currentList[0];
    } else {
      for (Card nextCard in nextList) {
        if (nextCard.durationR < 0) {
          return nextCard;
        }
      }
      if (nextList.length != 0) {
        return nextList[0];
      } else {
        return emptyCard; // ВСЁ ИЗУЧЕНО
      }
    }
  }
	return Card(id: 'err', native: 'Массив list пуст', foreign: '-');
}

int calculateCard(Card card, double factor) {
  var durCalculated;
  var timeCalculated;
  if (direction == 'native') {
    durCalculated = card.duration;
    timeCalculated = card.time;
  } else {
    durCalculated = card.durationR;
    timeCalculated = card.timeR;
  }
  var adding = 1000;
  var maxFactor = 1.5;
  if (durCalculated >= 0) {
    if (reverseTime > timeCalculated) { // если времени прошло больше запланированного
      var memTime = (reverseTime - timeCalculated) + durCalculated; // сколько времени прошло
      if (factor > 1) { // то если помню
        if (factor > 1.5) { // хорошо помню
          factor = (factor - 1.5) * 2 * (maxFactor - 1) + 1;
          durCalculated = memTime * factor;
        } else { // плоховато помню
          factor = (factor - 1.5) * 2 * (maxFactor - 1) + 1;
          durCalculated = memTime * factor;
        }
      } else { // не помню
        durCalculated = memTime * factor;
      }
    } else { // если показано вовремя или раньше положенного
      if (factor > 1) { // то если помню
      //
      } else { 
        durCalculated = durCalculated * factor + adding;// >?????
      }
    }
  } else { // НОВАЯ КАРТА
    if (factor > 1) {
      durCalculated = pow(factor, maxLevel) + 300; // >?????
    } else {
      durCalculated = factor * 300 + adding;
    }
  }
  return durCalculated.round();
}

void recalculate(Card card, int newDuration) {
  var rnd = Random();
  double mpx = rnd.nextDouble() * 0.06 + 0.97; // отклонение от точного
  if (direction == 'native') {
    card.duration = (newDuration * mpx).round();
    card.time = DateTime.now().millisecondsSinceEpoch + card.duration;
    if (card.durationR != -1) card.timeR = DateTime.now().millisecondsSinceEpoch + card.durationR;
  } else {
    card.durationR = (newDuration * mpx).round();
    card.timeR = DateTime.now().millisecondsSinceEpoch + card.durationR;
    if (card.duration != -1) card.time = DateTime.now().millisecondsSinceEpoch + card.duration;
  }
}

void fixReverse() {
  reverseTime = DateTime.now().millisecondsSinceEpoch;
}

// func addDeck(filepath):
// 	var finded = false
// 	var rows = R.fileToArray(filepath)
// 	for row in rows:
// 		for card in list:
// 			if card.id == row[0]:
// 				card.native = row[1]
// 				card.foreign = row[2]
// 				finded = true
// 				break
// 		if not finded:
// 			list.append(Card.new(row[0], row[1], row[2]))
// 			finded = false

// func saveDeck(filepath):
// 	var content = []
// 	for card in list:
// 		content.append([str(card.id), str(card.native), str(card.foreign)])
// 	R.arrayToFile(filepath, content)

saveTimes(String filepath) {
  List<List<String>> content = [];
  for (Card card in list) {
    if ((card.duration >= 0) || (card.durationR >= 0)) {
      content.add([(card.id).toString(),
      (card.time).toString(), (card.duration).toString(), 
      (card.timeR).toString(), (card.durationR).toString()]);
    }
  }
  arrayToFile(filepath, content);
}

// func edit(ccard, cn, cf):
// 	var modify = R.fileToArray('user://modify.csv')
// 	var changed = false
// 	for mod in modify:
// 		if mod[0] == ccard.id:
// 			mod[1] = cn
// 			mod[2] = cf
// 			changed = true
// 			break
// 	if not changed:
// 		modify.append([ccard.id, cn, cf])
// 	saveModify('user://modify.csv', modify)
// 	ccard.native = cn
// 	ccard.foreign = cf

// func saveModify(filepath, modifyList):
// 	var rows = []
// 	for c in modifyList:
// 		rows.append([str(c[0]), str(c[1]), str(c[2])])
// 	R.arrayToFile(filepath, rows)

}

List<List<String>> fileToArray(String filename) {
	List<List<String>> out = [];
  var lines = File(filename).readAsLinesSync();
  for(final line in lines){
    var csvLine = line.split('\t');
    out.add(csvLine);
  }
	return out;
}

void arrayToFile(String filename, List<List<String>> array) {
  var content = '';
  for (List<String> row in array) {
    content += row.join('\t') + '\n';
  }
  File(filename).writeAsStringSync(content);
}