import 'dart:math';

import 'package:flutter/foundation.dart';

typedef SudokuGrid = List<List<int>>;

SudokuGrid genSolved() {
  SudokuGrid grid = [];
  int filled = 0;
  while (filled < 81) {
    grid = List.generate(9, (index) => List.generate(9, (index) => 0));
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        final value = getValueForGrid(grid, i, j);
        if (value != null) {
          grid[i][j] = value;
          filled++;
        } else {
          i = 9;
          j = 9;
          filled = 0;
        }
      }
    }
  }
  return grid;
}

SudokuGrid genEmpty() {
  return List.generate(9, (index) => List.generate(9, (index) => 0));
}

SudokuGrid genFromList(List<int> list) {
  final length = list.length;
  assert(length == 81);
  final grid = genEmpty();
  for (int i = 0; i < 81; i++) {
    grid[i ~/ 9][i % 9] = list[i];
  }
  return grid;
}

int? getValueForGrid(SudokuGrid grid, int row, int col) {
  const possibleValues = [1, 2, 3, 4, 5, 6, 7, 8, 9];
  final rowValues = getRow(grid, row).toSet();
  final colValues = getColumn(grid, col).toSet();
  final squareValues = getBlock(grid, row: row, col: col).toSet();
  final values = possibleValues.where((value) {
    return !rowValues.contains(value) && !colValues.contains(value) && !squareValues.contains(value);
  }).toList();
  return values.isEmpty ? null : values[Random().nextInt(values.length)];
}

List<int> getRow(SudokuGrid grid, int row) {
  return grid[row];
}

List<int> getColumn(SudokuGrid grid, int col) {
  return grid.map((row) => row[col]).toList();
}

List<int> getBlock(SudokuGrid grid, {required int row, required int col}) {
  final rowStart = row ~/ 3 * 3;
  final colStart = col ~/ 3 * 3;
  final res = grid
      .sublist(rowStart, rowStart + 3)
      .map((row) {
        return row.sublist(colStart, colStart + 3);
      })
      .toList()
      .expand((x) => x)
      .toList();
  return res;
}

void printGrid(SudokuGrid grid) {
  for (int i = 0; i < 9; i++) {
    if (kDebugMode) print("row_$i: ${grid[i].join(' ')}");
  }
}

bool isValid(SudokuGrid sudoku, {required bool solved}) {
  for (int i = 0; i < 9; i++) {
    final row = getRow(sudoku, i);
    if (solved) {
      if (row.toSet().length < 9) return false;
    } else {
      final zeroCount = row.where((e) => e == 0).length;
      if (row.toSet().length + zeroCount < 9) return false;
    }
  }

  for (int i = 0; i < 9; i++) {
    final col = getColumn(sudoku, i);
    if (solved) {
      if (col.toSet().length < 9) return false;
    } else {
      final zeroCount = col.where((e) => e == 0).length;
      if (col.toSet().length + zeroCount < 9) return false;
    }
  }

  for (int i = 0; i < 9; i++) {
    for (int j = 0; j < 9; j++) {
      final block = getBlock(sudoku, row: i, col: j);
      if (solved) {
        if (block.toSet().length < 9) return false;
      } else {
        final zeroCount = block.where((e) => e == 0).length;
        if (block.toSet().length + zeroCount < 9) return false;
      }
    }
  }

  return true;
}

SudokuGrid genPuzzle(SudokuGrid solvedGrid, {required int difficulty}) {
  if (difficulty > 81) {
    throw Exception("Difficulty cannot be greater than 81");
  }
  if (difficulty < 0) {
    throw Exception("Difficulty cannot be less than 0");
  }
  final grid = deepCopyList(solvedGrid);
  int t = 0;
  while (t < difficulty) {
    final i = Random().nextInt(9);
    final j = Random().nextInt(9);
    if (grid[i][j] != 0) {
      grid[i][j] = 0;
      t++;
    }
  }

  return grid;
}

List<List<T>> deepCopyList<T>(List<List<T>> original) {
  return original.map((innerList) => List<T>.from(innerList)).toList();
}
