import 'dart:math';

class Card {
  
String id; // уникальный номер карточки
String native; // текст на родном языке
String foreign; // текст на арабском языке
late int time; // время следующего показа карточки в прямом направлении
late int timeR; // время следующего показа карточки в обратном направлении
late int duration; // пауза перед следующим показом в прямом направлении 
late int durationR; // пауза перед следующим показом в обратном направлении

  Card({
    required this.id, 
    required this.native, 
    required this.foreign
    }){
      time = DateTime.now().millisecondsSinceEpoch + 31536000000; // + год
      timeR = DateTime.now().millisecondsSinceEpoch + 31536000000; // + год
      duration = -1;
      durationR = -1;
    }

double get level => log(duration) < 0.0 ? 0.0 : log(duration); // getLevel()

double get levelR => log(durationR) < 0.0 ? 0.0 : log(durationR); //getLevelR()

// func save():
// 	return {
// 		"id": id,
// 		"native": native,
// 		"foreign": foreign
// 	}

// func saveTime():
// 	return {
// 		"id": id,
// 		"time": time,
// 		"duration": duration,
// 		"timeR": timeR,
// 		"durationR": durationR,
// 	}
}
