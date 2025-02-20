#!/bin/bash

DB_USERNAME=freecodecamp
DB_NAME=number_guess

PSQL="psql --username=$DB_USERNAME --dbname=$DB_NAME -t --no-align -c"

LOW=1
HIGH=1000
NUMBER=$(( RANDOM % (HIGH - LOW + 1) + LOW ))
echo $NUMBER

echo "Enter your username:"
read USERNAME_INSERTED
USERNAME_INSERTED=${USERNAME_INSERTED,,}

PLAYER_INFO=$($PSQL "SELECT * FROM players WHERE name ILIKE '$USERNAME_INSERTED';")

if [[ -z $PLAYER_INFO ]] 
then
  echo Welcome, $USERNAME_INSERTED! It looks like this is your first time here.
  INSERT_PLAYER_RESULT=$($PSQL "INSERT INTO players (name) VALUES ('$USERNAME_INSERTED');")
  PLAYER_INFO=$($PSQL "SELECT * FROM players WHERE name ILIKE '$USERNAME_INSERTED';")
  IFS='|' read -r PLAYER_ID PLAYER_NAME QTY_GAMES BEST_TRY <<< $PLAYER_INFO
else
  IFS='|' read -r PLAYER_ID PLAYER_NAME QTY_GAMES BEST_TRY <<< $PLAYER_INFO
  echo "Welcome back, $PLAYER_NAME! You have played $QTY_GAMES games, and your best game took $BEST_TRY guesses."
fi

# update player games played
GAMES=$QTY_GAMES
((++GAMES))

UPDATE_PLAYER_INFO=$($PSQL "UPDATE players SET qty_games=$GAMES WHERE player_id='$PLAYER_ID';")

#start game loop
game_over=false  
guesses=0

while [ "$game_over" = "false" ]; do  
  echo "Guess the secret number between 1 and 1000:"
  read guess
  if [[ "$guess" =~ ^-?[0-9]+$ ]]
  then
    ((++guesses))

    if [[ $guess -eq $NUMBER ]]
    then
      game_over=true 
      echo "You guessed it in $guesses tries. The secret number was $NUMBER. Nice job!"
    else 
      if [[ $guess -lt $NUMBER ]] 
      then
        echo "It's higher than that, guess again:"
      else
        echo "It's lower than that, guess again:"
      fi
    fi
  else
    echo That is not an integer, guess again:
  fi
done

#update best try if necessary
if [[ $guesses -lt $BEST_TRY || "$BEST_TRY" -eq 0 ]]
then 
  UPDATE_PLAYER_INFO=$($PSQL "UPDATE players SET best_try=$guesses WHERE player_id=$PLAYER_ID;")
fi