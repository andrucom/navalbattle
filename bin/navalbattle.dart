import 'dart:io';
import 'dart:math';
import 'dart:convert';

// Класс для хранения статистики игры
class GameStatistics {
  final String player1Name;
  final String player2Name;
  final DateTime gameStartTime;
  final DateTime gameEndTime;
  
  // Статистика для Игрока 1
  final int player1ShipsDestroyed;
  final int player1OwnShipsLost;
  final int player1Hits;
  final int player1Misses;
  final bool player1UsedCheat;
  
  // Статистика для Игрока 2
  final int player2ShipsDestroyed;
  final int player2OwnShipsLost;
  final int player2Hits;
  final int player2Misses;
  final bool player2UsedCheat;
  
  final String winner;
  final bool cheatUsed;
  
  GameStatistics({
    required this.player1Name,
    required this.player2Name,
    required this.gameStartTime,
    required this.gameEndTime,
    required this.player1ShipsDestroyed,
    required this.player1OwnShipsLost,
    required this.player1Hits,
    required this.player1Misses,
    required this.player1UsedCheat,
    required this.player2ShipsDestroyed,
    required this.player2OwnShipsLost,
    required this.player2Hits,
    required this.player2Misses,
    required this.player2UsedCheat,
    required this.winner,
    required this.cheatUsed,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'game_info': {
        'date': gameStartTime.toIso8601String(),
        'duration_seconds': gameEndTime.difference(gameStartTime).inSeconds,
        'winner': winner,
        'cheat_used': cheatUsed,
      },
      'player1': {
        'name': player1Name,
        'ships_destroyed': player1ShipsDestroyed,
        'own_ships_lost': player1OwnShipsLost,
        'hits': player1Hits,
        'misses': player1Misses,
        'total_shots': player1Hits + player1Misses,
        'accuracy': player1Hits + player1Misses > 0 
            ? ((player1Hits / (player1Hits + player1Misses)) * 100).toStringAsFixed(1) + '%'
            : '0%',
        'ships_remaining': 10 - player1OwnShipsLost,
        'ships_total': 10,
        'used_cheat': player1UsedCheat,
      },
      'player2': {
        'name': player2Name,
        'ships_destroyed': player2ShipsDestroyed,
        'own_ships_lost': player2OwnShipsLost,
        'hits': player2Hits,
        'misses': player2Misses,
        'total_shots': player2Hits + player2Misses,
        'accuracy': player2Hits + player2Misses > 0 
            ? ((player2Hits / (player2Hits + player2Misses)) * 100).toStringAsFixed(1) + '%'
            : '0%',
        'ships_remaining': 10 - player2OwnShipsLost,
        'ships_total': 10,
        'used_cheat': player2UsedCheat,
      },
    };
  }
  
  String toReadableString() {
    final duration = gameEndTime.difference(gameStartTime);
    return '''
🔥🔥🔥 ФИНАЛЬНАЯ СТАТИСТИКА ИГРЫ 🔥🔥🔥

📅 Дата игры: ${gameStartTime.toString().split(' ')[0]}
⏱️  Продолжительность: ${duration.inMinutes} мин ${duration.inSeconds % 60} сек
🏆 Победитель: $winner
🚨 Чит-код использован: ${cheatUsed ? 'ДА' : 'НЕТ'}

📊 СТАТИСТИКА ИГРОКОВ:

${player1Name.toUpperCase()}:
✅ Кораблей уничтожено у противника: $player1ShipsDestroyed
❌ Своих кораблей потеряно: $player1OwnShipsLost
🎯 Осталось кораблей на поле: ${10 - player1OwnShipsLost}/10
💥 Попаданий: $player1Hits
💦 Промахов: $player1Misses
🎯 Точность: ${player1Hits + player1Misses > 0 ? ((player1Hits / (player1Hits + player1Misses)) * 100).toStringAsFixed(1) : '0'}%
🔫 Всего выстрелов: ${player1Hits + player1Misses}
🎮 Чит-код использован: ${player1UsedCheat ? 'ДА' : 'НЕТ'}

${player2Name.toUpperCase()}:
✅ Кораблей уничтожено у противника: $player2ShipsDestroyed
❌ Своих кораблей потеряно: $player2OwnShipsLost
🎯 Осталось кораблей на поле: ${10 - player2OwnShipsLost}/10
💥 Попаданий: $player2Hits
💦 Промахов: $player2Misses
🎯 Точность: ${player2Hits + player2Misses > 0 ? ((player2Hits / (player2Hits + player2Misses)) * 100).toStringAsFixed(1) : '0'}%
🔫 Всего выстрелов: ${player2Hits + player2Misses}
🎮 Чит-код использован: ${player2UsedCheat ? 'ДА' : 'НЕТ'}

🎮 Спасибо за игру! Статистика сохранена в файл.
''';
  }
}

class Position {
  final int x;
  final int y;
  
  Position(this.x, this.y);
  
  String toReadable() => '${x + 1},${y + 1}';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class Cell {
  static const int empty = 0;
  static const int ship = 1;
  static const int hit = 2;
  static const int miss = 3;
  
  final int state;
  final int? shipId;
  
  Cell(this.state, {this.shipId});
  
  bool get isShip => state == ship;
  bool get isHit => state == hit;
  bool get isMiss => state == miss;
  bool get isEmpty => state == empty;
  
  @override
  String toString() {
    switch (state) {
      case ship: return 'S';
      case hit: return 'X';
      case miss: return 'O';
      default: return '.';
    }
  }
}

class Board {
  static const int size = 10;
  final List<List<Cell>> grid;
  int shipsRemaining = 0;
  final Map<int, int> shipHealth = {};
  int _shipCounter = 0;
  final Map<int, List<Position>> _shipPositions = {};
  
  Board() : grid = List.generate(size, (_) => List.generate(size, (_) => Cell(Cell.empty))) {
    _initializeBoard();
  }
  
  void _initializeBoard() {
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        grid[y][x] = Cell(Cell.empty);
      }
    }
  }
  
  bool canPlaceShip(int x, int y, int length, bool isVertical) {
    // Проверка границ
    if (isVertical) {
      if (y < 0 || y + length > size) return false;
    } else {
      if (x < 0 || x + length > size) return false;
    }
    
    // Проверка пересечений (только сами корабли, без расстояния)
    for (var i = 0; i < length; i++) {
      final nx = isVertical ? x : x + i;
      final ny = isVertical ? y + i : y;
      
      if (nx < 0 || nx >= size || ny < 0 || ny >= size) {
        return false;
      }
      
      if (grid[ny][nx].isShip) {
        return false;
      }
    }
    
    return true;
  }
  
  List<Position> getAvailablePositions(int length) {
    final positions = <Position>[];
    
    // Проверяем ВСЕ возможные позиции на поле
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        // Проверяем горизонтальное размещение
        if (x + length <= size && canPlaceShip(x, y, length, false)) {
          positions.add(Position(x, y));
        }
        // Проверяем вертикальное размещение
        if (y + length <= size && canPlaceShip(x, y, length, true)) {
          positions.add(Position(x, y));
        }
      }
    }
    
    return positions;
  }
  
  bool placeShip(int x, int y, int length, bool isVertical) {
    if (!canPlaceShip(x, y, length, isVertical)) {
      return false;
    }
    
    // Размещение корабля
    final shipId = ++_shipCounter;
    shipHealth[shipId] = length;
    shipsRemaining++;
    _shipPositions[shipId] = [];
    
    for (var i = 0; i < length; i++) {
      final nx = isVertical ? x : x + i;
      final ny = isVertical ? y + i : y;
      grid[ny][nx] = Cell(Cell.ship, shipId: shipId);
      _shipPositions[shipId]!.add(Position(nx, ny));
    }
    
    return true;
  }
  
  // Метод для поиска ЛЮБОЙ свободной позиции для корабля
  Position? findAnyFreePosition(int length) {
    // Сначала пробуем вертикальное размещение
    for (var y = 0; y <= size - length; y++) {
      for (var x = 0; x < size; x++) {
        if (canPlaceShip(x, y, length, true)) {
          return Position(x, y);
        }
      }
    }
    
    // Затем пробуем горизонтальное размещение
    for (var y = 0; y < size; y++) {
      for (var x = 0; x <= size - length; x++) {
        if (canPlaceShip(x, y, length, false)) {
          return Position(x, y);
        }
      }
    }
    
    return null;
  }
  
  String receiveShot(Position pos) {
    final cell = grid[pos.y][pos.x];
    
    if (cell.isHit || cell.isMiss) {
      return "repeat";
    }
    
    if (cell.isShip) {
      grid[pos.y][pos.x] = Cell(Cell.hit, shipId: cell.shipId);
      
      // Проверка потопления корабля
      final shipId = cell.shipId!;
      shipHealth[shipId] = (shipHealth[shipId] ?? 0) - 1;
      
      if (shipHealth[shipId] == 0) {
        shipsRemaining--;
        if (shipsRemaining == 0) {
          return "win";
        }
        return "sunk";
      }
      return "hit";
    } else {
      grid[pos.y][pos.x] = Cell(Cell.miss);
      return "miss";
    }
  }
  
  // Метод для уничтожения всех кораблей (чит-код)
  int destroyAllShips() {
    int totalHits = 0;
    
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final cell = grid[y][x];
        if (cell.isShip && !cell.isHit) {
          grid[y][x] = Cell(Cell.hit, shipId: cell.shipId);
          totalHits++;
          
          // Обновляем здоровье корабля
          final shipId = cell.shipId!;
          shipHealth[shipId] = (shipHealth[shipId] ?? 0) - 1;
          
          // Если корабль потоплен, уменьшаем счетчик
          if (shipHealth[shipId] == 0) {
            shipsRemaining--;
          }
        }
      }
    }
    
    return totalHits;
  }
  
  void display({bool showShips = false}) {
    stdout.write('   ');
    for (var x = 1; x <= size; x++) {
      stdout.write('${x.toString().padLeft(2)} ');
    }
    stdout.writeln();
    
    for (var y = 0; y < size; y++) {
      stdout.write('${(y + 1).toString().padLeft(2)} ');
      for (var x = 0; x < size; x++) {
        final cell = grid[y][x];
        String symbol;
        
        if (cell.isHit) {
          symbol = '🔥';
        } else if (cell.isMiss) {
          symbol = '💧';
        } else if (showShips && cell.isShip) {
          symbol = '⛴️';
        } else {
          symbol = '🌊';
        }
        
        stdout.write(' $symbol');
      }
      stdout.writeln();
    }
  }
  
  void displayShipsOnly() {
    stdout.write('   ');
    for (var x = 1; x <= size; x++) {
      stdout.write('${x.toString().padLeft(2)} ');
    }
    stdout.writeln();
    
    for (var y = 0; y < size; y++) {
      stdout.write('${(y + 1).toString().padLeft(2)} ');
      for (var x = 0; x < size; x++) {
        final cell = grid[y][x];
        String symbol = cell.isShip ? '⛴️' : '🌊';
        stdout.write(' $symbol');
      }
      stdout.writeln();
    }
  }
  
  int getDestroyedShipsCount() {
    return 10 - shipsRemaining;
  }
  
  int getTotalShipCells() {
    return _shipPositions.values.fold(0, (sum, positions) => sum + positions.length);
  }
}

class Player {
  final String name;
  final Board board = Board();
  
  // Статистика игрока
  int hits = 0;
  int misses = 0;
  int shipsDestroyed = 0;
  int ownShipsLost = 0;
  bool usedCheat = false;
  
  Player(this.name);
  
  void setupShips() {
    stdout.write('$name, хотите авто-расстановку кораблей? (y/n): ');
    final choice = stdin.readLineSync()?.trim().toLowerCase();
    final autoPlace = choice == 'y' || choice == 'yes';
    
    if (autoPlace) {
      _autoPlaceShips();
      print('$name: корабли расставлены автоматически.');
    } else {
      _manualPlaceShips();
    }
  }
  
  void _autoPlaceShips() {
    final shipLengths = [5, 4, 4, 3, 3, 3, 2, 2, 2, 2];
    
    for (final length in shipLengths) {
      if (!_tryPlaceShipAuto(length)) {
        print('⚠️ Автоматическая расстановка не удалась для корабля длиной $length.');
        print('🔄 Попытка альтернативного алгоритма размещения...');
        
        if (!_tryPlaceShipAlternative(length)) {
          print('❌ Не удалось разместить корабль автоматически. Переходим к ручной расстановке.');
          _manualPlaceShip(length);
        }
      }
    }
    
    print('✅ Автоматическая расстановка завершена успешно!');
  }
  
  bool _tryPlaceShipAuto(int length) {
    final availablePositions = board.getAvailablePositions(length);
    
    if (availablePositions.isEmpty) {
      return false;
    }
    
    // Выбираем случайную позицию
    final random = Random();
    final position = availablePositions[random.nextInt(availablePositions.length)];
    
    // Сначала пробуем вертикальное размещение
    if (board.canPlaceShip(position.x, position.y, length, true)) {
      return board.placeShip(position.x, position.y, length, true);
    }
    
    // Если не получилось, пробуем горизонтальное
    if (board.canPlaceShip(position.x, position.y, length, false)) {
      return board.placeShip(position.x, position.y, length, false);
    }
    
    return false;
  }
  
  bool _tryPlaceShipAlternative(int length) {
    // Альтернативный алгоритм: ищем ЛЮБУЮ свободную позицию
    final position = board.findAnyFreePosition(length);
    
    if (position == null) {
      return false;
    }
    
    // Пробуем сначала вертикально, затем горизонтально
    if (board.canPlaceShip(position.x, position.y, length, true)) {
      return board.placeShip(position.x, position.y, length, true);
    }
    
    if (board.canPlaceShip(position.x, position.y, length, false)) {
      return board.placeShip(position.x, position.y, length, false);
    }
    
    return false;
  }
  
  void _manualPlaceShips() {
    final shipLengths = [5, 4, 4, 3, 3, 3, 2, 2, 2, 2];
    
    for (final length in shipLengths) {
      _manualPlaceShip(length);
    }
  }
  
  void _manualPlaceShip(int length) {
    int attempts = 0;
    while (true) {
      attempts++;
      
      print('\nТекущее поле $name:');
      board.displayShipsOnly();
      
      print('\nРазместите корабль длиной $length:');
      print('Формат: x,y,направление (h - горизонтально, v - вертикально)');
      print('Пример: 3,5,h');
      print('Попытка $attempts из 10 (введите "skip" для пропуска):');
      
      final input = stdin.readLineSync()?.trim();
      
      if (input == null || input.isEmpty) continue;
      
      // Возможность пропустить корабль для отладки
      if (input.toLowerCase() == 'skip' && attempts >= 5) {
        print('⚠️ Пропускаем корабль длиной $length (для отладки)');
        return;
      }
      
      final parts = input.split(',');
      if (parts.length != 3) {
        print('❌ Неверный формат. Попробуйте снова.');
        continue;
      }
      
      try {
        final x = int.parse(parts[0].trim()) - 1;
        final y = int.parse(parts[1].trim()) - 1;
        final dir = parts[2].trim().toLowerCase();
        final isVertical = dir == 'v';
        
        if (x < 0 || x >= Board.size || y < 0 || y >= Board.size) {
          print('❌ Координаты вне поля. Используйте значения от 1 до ${Board.size}.');
          continue;
        }
        
        if (board.placeShip(x, y, length, isVertical)) {
          print('✅ Корабль успешно размещен!');
          break;
        } else {
          print('❌ Корабль пересекается с другими или выходит за границы. Попробуйте другое место.');
          
          // Подсказка о доступных позициях
          if (attempts >= 3) {
            final freePos = board.findAnyFreePosition(length);
            if (freePos != null) {
              print('💡 Подсказка: попробуйте координаты ${freePos.x + 1},${freePos.y + 1} с направлением v или h');
            }
          }
        }
      } catch (e) {
        print('❌ Ошибка ввода: $e. Используйте формат: x,y,направление');
      }
      
      if (attempts >= 10) {
        print('⚠️ Слишком много неудачных попыток. Пробуем автоматическое размещение для этого корабля.');
        if (!_tryPlaceShipAuto(length) && !_tryPlaceShipAlternative(length)) {
          print('❌ Не удалось разместить корабль даже автоматически. Пропускаем.');
        }
        break;
      }
    }
  }
  
  Position? askShot() {
    while (true) {
      stdout.write('\n$name, введите координаты для выстрела (x,y) или чит-код "godmode": ');
      final input = stdin.readLineSync()?.trim();
      
      if (input == null || input.isEmpty) continue;
      
      // Обработка чит-кода
      if (input.toLowerCase() == 'godmode') {
        print('🚨 ЧИТ-КОД АКТИВИРОВАН! Все корабли противника уничтожены!');
        usedCheat = true;
        return null; // Специальное значение для чит-кода
      }
      
      final parts = input.split(',');
      if (parts.length != 2) {
        print('❌ Неверный формат. Используйте: x,y или "godmode" для чит-кода');
        continue;
      }
      
      try {
        final x = int.parse(parts[0].trim()) - 1;
        final y = int.parse(parts[1].trim()) - 1;
        
        if (x < 0 || x >= Board.size || y < 0 || y >= Board.size) {
          print('❌ Координаты вне поля. Используйте значения от 1 до ${Board.size}.');
          continue;
        }
        
        return Position(x, y);
      } catch (e) {
        print('❌ Ошибка ввода: $e. Используйте числа, разделенные запятой.');
      }
    }
  }
  
  void updateStatistics(String result) {
    switch (result) {
      case 'hit':
        hits++;
        break;
      case 'miss':
        misses++;
        break;
      case 'sunk':
        hits++;
        shipsDestroyed++;
        break;
      case 'win':
        hits++;
        shipsDestroyed++;
        break;
      case 'cheat':
        // При чит-коде: 20 попаданий (все палубы), 0 промахов
        hits += 20;
        shipsDestroyed = 10;
        break;
    }
  }
  
  void updateOwnShipsLost() {
    ownShipsLost = 10 - board.shipsRemaining;
  }
  
  int applyCheat() {
    final totalCells = board.getTotalShipCells();
    final hitsMade = board.destroyAllShips();
    shipsDestroyed = 10; // Все корабли уничтожены
    hits += hitsMade;
    return hitsMade;
  }
}

class BattleshipGame {
  late Player player1;
  late Player player2;
  late DateTime gameStartTime;
  bool cheatUsed = false;
  
  void start() {
    gameStartTime = DateTime.now();
    
    print('⚓️ ДОБРО ПОЖАЛОВАТЬ В МОРСКОЙ БОЙ! ⚓️');
    print('Версия: 2.3 (с исправленной расстановкой кораблей)');
    print('-' * 50);
    print('💡 СЕКРЕТНЫЙ ЧИТ-КОД: Введите "godmode" вместо координат для моментальной победы!');
    print('-' * 50);
    
    player1 = Player('Игрок 1');
    player2 = Player('Игрок 2');
    
    print('\n${player1.name}, настройте свое поле:');
    player1.setupShips();
    
    clearScreen();
    
    print('\n${player2.name}, настройте свое поле:');
    player2.setupShips();
    
    clearScreen();
    print('✅ Все корабли расставлены! Начинаем игру!\n');
    
    play();
  }
  
  void clearScreen() {
    print('\n' * 40);
  }
  
  void play() {
    var currentPlayer = player1;
    var opponent = player2;
    
    while (true) {
      print('=' * 50);
      print('${currentPlayer.name}, ваш ход!');
      
      print('\nВаше поле:');
      currentPlayer.board.display(showShips: true);
      
      print('\nПоле противника:');
      opponent.board.display(showShips: false);
      
      final shotPos = currentPlayer.askShot();
      
      // Обработка чит-кода
      if (shotPos == null) {
        // Применение чит-кода
        currentPlayer.applyCheat();
        cheatUsed = true;
        
        clearScreen();
        print('${currentPlayer.name} активировал чит-код "godmode"! 💥');
        print('Все корабли противника уничтожены!');
        
        final gameEndTime = DateTime.now();
        showFinalResults(gameEndTime);
        saveGameStatistics(gameEndTime, currentPlayer.name);
        return;
      }
      
      final result = opponent.board.receiveShot(shotPos);
      
      // Обновление статистики
      currentPlayer.updateStatistics(result);
      opponent.updateOwnShipsLost();
      
      clearScreen();
      
      print('${currentPlayer.name} стреляет в ${shotPos.toReadable()} → ');
      
      switch (result) {
        case 'hit':
          print('✅ ПОПАДАНИЕ!');
          continue; // Тот же игрок стреляет снова
        case 'miss':
          print('❌ МИМО!');
          break;
        case 'sunk':
          print('💥 КОРАБЛЬ ПОТОПЛЕН!');
          continue; // Тот же игрок стреляет снова
        case 'repeat':
          print('⚠️ УЖЕ СТРЕЛЯЛИ СЮДА!');
          continue; // Тот же игрок стреляет снова
        case 'win':
          print('🎉 ПОБЕДА! ${currentPlayer.name} выиграл игру!');
          final gameEndTime = DateTime.now();
          showFinalResults(gameEndTime);
          saveGameStatistics(gameEndTime, currentPlayer.name);
          return;
      }
      
      // Смена игрока
      final temp = currentPlayer;
      currentPlayer = opponent;
      opponent = temp;
      
      print('\nНажмите Enter, чтобы передать ход противнику...');
      stdin.readLineSync();
      clearScreen();
    }
  }
  
  void showFinalResults(DateTime gameEndTime) {
    print('\n' + '=' * 50);
    print('📊 ФИНАЛЬНАЯ СТАТИСТИКА');
    print('=' * 50);
    
    // Обновление финальной статистики
    player1.updateOwnShipsLost();
    player2.updateOwnShipsLost();
    
    print('\n${player1.name}:');
    print('✅ Кораблей уничтожено: ${player1.shipsDestroyed}');
    print('❌ Своих кораблей потеряно: ${player1.ownShipsLost}');
    print('🎯 Осталось кораблей: ${10 - player1.ownShipsLost}/10');
    print('💥 Попаданий: ${player1.hits}');
    print('💦 Промахов: ${player1.misses}');
    print('🔫 Всего выстрелов: ${player1.hits + player1.misses}');
    print('🎯 Точность: ${player1.hits + player1.misses > 0 ? ((player1.hits / (player1.hits + player1.misses)) * 100).toStringAsFixed(1) : '0'}%');
    print('🎮 Чит-код: ${player1.usedCheat ? 'ИСПОЛЬЗОВАН' : 'НЕ ИСПОЛЬЗОВАН'}');
    
    print('\n${player2.name}:');
    print('✅ Кораблей уничтожено: ${player2.shipsDestroyed}');
    print('❌ Своих кораблей потеряно: ${player2.ownShipsLost}');
    print('🎯 Осталось кораблей: ${10 - player2.ownShipsLost}/10');
    print('💥 Попаданий: ${player2.hits}');
    print('💦 Промахов: ${player2.misses}');
    print('🔫 Всего выстрелов: ${player2.hits + player2.misses}');
    print('🎯 Точность: ${player2.hits + player2.misses > 0 ? ((player2.hits / (player2.hits + player2.misses)) * 100).toStringAsFixed(1) : '0'}%');
    print('🎮 Чит-код: ${player2.usedCheat ? 'ИСПОЛЬЗОВАН' : 'НЕ ИСПОЛЬЗОВАН'}');
    
    final duration = gameEndTime.difference(gameStartTime);
    print('\n⏱️ Продолжительность игры: ${duration.inMinutes} мин ${duration.inSeconds % 60} сек');
    print('🚨 Общий статус чит-кода: ${cheatUsed ? 'ИСПОЛЬЗОВАН' : 'НЕ ИСПОЛЬЗОВАН'}');
  }
  
  void saveGameStatistics(DateTime gameEndTime, String winnerName) {
    try {
      // Создание каталога для статистики
      final statsDir = Directory('game_statistics');
      if (!statsDir.existsSync()) {
        statsDir.createSync(recursive: true);
        print('📁 Создан каталог для статистики: ${statsDir.path}');
      }
      
      // Формирование имени файла с временной меткой
      final timestamp = gameStartTime.millisecondsSinceEpoch;
      final fileName = 'game_stats_$timestamp.json';
      final filePath = '${statsDir.path}/$fileName';
      
      // Создание объекта статистики
      final stats = GameStatistics(
        player1Name: player1.name,
        player2Name: player2.name,
        gameStartTime: gameStartTime,
        gameEndTime: gameEndTime,
        player1ShipsDestroyed: player1.shipsDestroyed,
        player1OwnShipsLost: player1.ownShipsLost,
        player1Hits: player1.hits,
        player1Misses: player1.misses,
        player1UsedCheat: player1.usedCheat,
        player2ShipsDestroyed: player2.shipsDestroyed,
        player2OwnShipsLost: player2.ownShipsLost,
        player2Hits: player2.hits,
        player2Misses: player2.misses,
        player2UsedCheat: player2.usedCheat,
        winner: winnerName,
        cheatUsed: cheatUsed,
      );
      
      // Запись в JSON файл
      final file = File(filePath);
      file.writeAsStringSync(json.encode(stats.toJson()), encoding: utf8);
      
      // Дополнительно создаем текстовый файл с читаемой статистикой
      final textFileName = 'game_stats_$timestamp.txt';
      final textFilePath = '${statsDir.path}/$textFileName';
      final textFile = File(textFilePath);
      textFile.writeAsStringSync(stats.toReadableString(), encoding: utf8);
      
      print('\n✅ Статистика успешно сохранена!');
      print('📁 JSON файл: $filePath');
      print('📄 Текстовый файл: $textFilePath');
      
      // Особое сообщение если использован чит-код
      if (cheatUsed) {
        print('\n' + '!' * 60);
        print('!!! ВНИМАНИЕ: В ЭТОЙ ИГРЕ БЫЛ ИСПОЛЬЗОВАН ЧИТ-КОД "godmode" !!!');
        print('!!! СТАТИСТИКА МОЖЕТ БЫТЬ НЕКОРРЕКТНОЙ !!!');
        print('!' * 60);
      }
      
    } catch (e) {
      print('❌ Ошибка при сохранении статистики: $e');
    }
  }
}

void main() {
  final game = BattleshipGame();
  game.start();
  
  print('\n' + '=' * 60);
  print('💡 ИГРА ЗАВЕРШЕНА! Все результаты сохранены в каталоге "game_statistics"');
  print('📁 Вы можете найти там файлы со статистикой в форматах JSON и TXT');
  print('🎮 СЕКРЕТНЫЙ ЧИТ-КОД: "godmode" (вводится вместо координат выстрела)');
  print('=' * 60);
}