#include "montador.h"
#include <stdio.h>
#include <stdlib.h>

/* 
 * Argumentos:
 *  entrada: cadeia de caracteres com o conteudo do arquivo de entrada.
 *  tamanho: tamanho da cadeia.
 * Retorna:
 *  1 caso haja erro na montagem; 
 *  0 caso não haja erro.
 */
int processarEntrada(char* entrada, unsigned tamanho){

  // Variáveis para debugar
  int line_aux, debug = 1, debug1 = 1;

  unsigned line = 0, in_word = 0, end_word, size_word;
  int i, aux;
  char *word;
  
  for (i = 0; i < tamanho; i++){
    
    if ((entrada[i] == 32) || (entrada[i] == 10)){  // Verifica posição i == " " || i == "/n" para detectar uma palavra
      
      end_word = i;

      size_word = end_word - in_word       

      for (aux = 0; aux < size_word; aux++ , in_word++){
        word[aux] = entrada[in_word];
      }

      printf("%s\n", word);

      word[end_word] = "\0";
      in_word = i+1;
    }

    if (entrada[i] == 10){ //Acrescenta linha caso i == "\n"
      line++;
    }
    
  }

  return 0; 
}

int valid_DefLabel(char* palavra, unsigned size){

}