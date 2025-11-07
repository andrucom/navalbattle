import 'dart:io';
import 'dart:math';

void main() {
  final game = BattleshipGame();
  game.start();
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
  
  bool placeShip(int x, int y, int length, bool isVertical) {
    // Проверка границ
    if (isVertical) {
      if (y + length > size) return false;
    } else {
      if (x + length > size) return false;
    }
    
    // Проверка пересечений и расстояния
    for (var i = -1; i <= (isVertical ? length : 1); i++) {
      for (var j = -1; j <= (isVertical ? 1 : length); j++) {
        var checkX = x + (isVertical ? j : i);
        var checkY = y + (isVertical ? i : j);
        
        if (checkX >= 0 && checkX < size && checkY >= 0 && checkY < size) {
          if (grid[checkY][checkX].isShip) {
            return false;
          }
        }
      }
    }
    
    // Размещение корабля
    final shipId = ++_shipCounter;
    shipHealth[shipId] = length;
    shipsRemaining++;
    
    for (var i = 0; i < length; i++) {
      final nx = isVertical ? x : x + i;
      final ny = isVertical ? y + i : y;
      grid[ny][nx] = Cell(Cell.ship, shipId: shipId);
    }
    
    return true;
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
}

class Player {
  final String name;
  final Board board = Board();
  
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
    final random = Random();
    final shipLengths = [5, 4, 4, 3, 3, 3, 2, 2, 2, 2];
    
    for (final length in shipLengths) {
      bool placed = false;
      int attempts = 0;
      
      while (!placed && attempts < 100) {
        attempts++;
        final x = random.nextInt(Board.size);
        final y = random.nextInt(Board.size);
        final isVertical = random.nextBool();
        
        placed = board.placeShip(x, y, length, isVertical);
      }
      
      if (!placed) {
        print('⚠️ Не удалось автоматически разместить корабль длиной $length. Попробуйте вручную.');
        _manualPlaceShip(length);
      }
    }
  }
  
  void _manualPlaceShips() {
    final shipLengths = [5, 4, 4, 3, 3, 3, 2, 2, 2, 2];
    
    for (final length in shipLengths) {
      _manualPlaceShip(length);
    }
  }
  
  void _manualPlaceShip(int length) {
    while (true) {
      print('\nТекущее поле $name:');
      board.displayShipsOnly();
      
      print('\nРазместите корабль длиной $length:');
      print('Формат: x,y,направление (h - горизонтально, v - вертикально)');
      print('Пример: 3,5,h');
      
      final input = stdin.readLineSync()?.trim();
      if (input == null || input.isEmpty) continue;
      
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
        }
      } catch (e) {
        print('❌ Ошибка ввода: $e. Используйте формат: x,y,направление');
      }
    }
  }
  
  Position askShot() {
    while (true) {
      stdout.write('\n$name, введите координаты для выстрела (x,y): ');
      final input = stdin.readLineSync()?.trim();
      
      if (input == null || input.isEmpty) continue;
      
      final parts = input.split(',');
      if (parts.length != 2) {
        print('❌ Неверный формат. Используйте: x,y');
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
}

class BattleshipGame {
  late Player player1;
  late Player player2;
  
  void start() {
    print('⚓️ ДОБРО ПОЖАЛОВАТЬ В МОРСКОЙ БОЙ! ⚓️');
    print('Версия: 1.0');
    print('Автор: Dart Battleship');
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
      final result = opponent.board.receiveShot(shotPos);
      
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
          showFinalResults();
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
  
  void showFinalResults() {
    print('\n' + '=' * 50);
    print('📊 ФИНАЛЬНЫЕ РЕЗУЛЬТАТЫ');
    print('=' * 50);
    
    print('\nПоле ${player1.name}:');
    player1.board.display(showShips: true);
    
    print('\nПоле ${player2.name}:');
    player2.board.display(showShips: true);
    
    print('\nСпасибо за игру! 🎮');
  }
}