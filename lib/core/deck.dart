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
    int duration;
    int time;
    
    for (Card c in list) {
      duration = (direction == 'native') ? c.duration : c.durationR;
      time = (direction == 'native') ? c.time : c.timeR;
      // вычищаем от выученных карточек
      if (duration > maxDuration) {
        sumEnd += 1; // считаем изученые / удалённые
        continue;
      }
      // разделяем на два списка Текущих и Будущих карточек
      if (time <= dealTime) {
        currentList.add(c);
        sumCur += 1; // считаем текущие
      } else {
        nextList.add(c);
        if (duration == -1) {
          sumNew += 1; // считаем новые
        } else {
          sumNext += 1; // считаем следующие
        }
      }
    }
    // и сортируем эти 2 списка
    currentList.sort((b, a) => a.time.compareTo(b.time));
    nextList.sort((a, b) => a.time.compareTo(b.time));
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
  if (direction == 'auto') {
    direction = 'native';
    listsPrepare();
    int nativeSum = sumCur + sumNew;
    direction = 'foreign';
    listsPrepare();
    int foreignSum = sumCur + sumNew;
    Random rnd = Random();
    int rndInt = rnd.nextInt(foreignSum + nativeSum);
    if (rndInt < nativeSum) {
      direction = 'native';
    } else {
      direction = 'foreign';
    }
  }
  listsPrepare();
  // изучаем в первую очередь всё из Текущего списка
  if (currentList.length != 0) {
    fromList = 'darkblue';
    return currentList[0]; // вернуть из Текущего списка
  } // а после из Будующего (Ново-следующего)
  else {
    int duration;
    for (Card nextCard in nextList) {
      duration = (direction == 'native') ? nextCard.duration : nextCard.durationR;
      if (duration < 0) {
        fromList = 'darkgreen';
        return nextCard;  // вернуть из Нового списка
      }
    }
    // Новый список и Текущий закончился
    if (nextList.length != 0) {
      fromList = 'darkred';
      return nextList[0]; // вернуть первую из Следующего списка
    } else {
      fromList = 'black';
      return Card(id: 'err', native: 'ВСЁ ИЗУЧЕНО', foreign: '-'); // ВСЁ ИЗУЧЕНО
    }
  }
	return Card(id: 'err', native: 'Массив list пуст', foreign: '-');
}

int calculateDuration(Card card, double factor) {
  double duration = (direction == 'native') ? card.duration * 1.0 : card.durationR * 1.0;
  int time = (direction == 'native') ? card.time : card.timeR;
  double maxFactor = 1.5;
  if (duration >= 0) {
    if (reverseTime > time) { // если времени прошло больше запланированного
      double memTime = (reverseTime - time) + duration; // сколько времени прошло
      if (factor > 1) { // то если помню
        if (factor > 1.5) { // хорошо помню
          factor = (factor - 1.5) * 2 * (maxFactor - 1) + 1;
          duration = memTime * factor;
        } else { // плоховато помню
          factor = (factor - 1.5) * 2 * (maxFactor - 1) + 1;
          duration = memTime * factor;
        }
      } else { // не помню
        duration = memTime * factor;
      }
    } else { // если показано вовремя или раньше положенного
      int memTime = time - reverseTime; // сколько времени прошло
      if (factor > 1) { // то если помню
        duration = memTime * factor;
      } else { 
        duration *= factor;  // >?????
      }
    }
  } else { // НОВАЯ КАРТА
    if (factor > 1) {
      duration = pow(factor, maxLevel) + 300; // >?????
    } else {
      duration = factor * 300;
    }
  }
  return duration.round();
}

void recalculateCard(Card card, int newDuration, double answer) {
	newDuration += 1000;
  Random rnd = Random();
  double mpx = rnd.nextDouble() * 0.06 + 0.97; // отклонение от точного
  if (direction == 'native') {
    card.duration = (newDuration * mpx).round();
    card.time = DateTime.now().millisecondsSinceEpoch + card.duration;
    if (card.durationR != -1) {
      card.durationR = (answer < 1) ? card.durationR ~/ (2 - answer) : card.durationR;
      card.timeR = DateTime.now().millisecondsSinceEpoch + card.durationR;
    }
  } else {
    card.durationR = (newDuration * mpx).round();
    card.timeR = DateTime.now().millisecondsSinceEpoch + card.durationR;
    if (card.duration != -1) {
      card.duration = (answer < 1) ? card.duration ~/ (2 - answer) : card.duration;
      card.time = DateTime.now().millisecondsSinceEpoch + card.duration;
    }
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