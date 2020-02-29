from random import randint

board = []


for x in range(0, 5):
  board.append(["O"] * 5)

def print_board(board):
  for row in board:
    print " ".join(row)

def random_row(board):
  return randint(0, len(board) - 1)

def random_col(board):
  return randint(0, len(board[0]) - 1)

def main_game():
    global turns
    print "You have %s turns left" % turns    
    if turns > 0:
      turns = turns - 1
      guess_row = int(raw_input("Guess Row: "))
      guess_col = int(raw_input("Guess Col: "))
      game_end(guess_row, guess_col)
    else:
      print "You have no turns left, you lose."
       
def game_end(guess_row, guess_col):
  if guess_row == ship_row and guess_col == ship_col:
    print "Congratulations! You sank my battleship!"
  else:
    if guess_row not in range(5) or guess_col not in range(5):
      print "Oops, that's not even in the ocean. Try again."
      main_game()
    elif board[guess_row][guess_col] == "X":
      print "You guessed that one already."
      main_game()
    else:
      print "You missed my battleship!"
      board[guess_row][guess_col] = "X"
      print_board(board)
      print "Try again."
      main_game()


# Write your code below!
turns = 4
print_board(board)
ship_row = random_row(board)
ship_col = random_col(board)
print ship_row
print ship_col

main_game()
