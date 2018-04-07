#include "montador.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>



int Authe_DefLabel(char* word, unsigned size);
int Authe_Directive(char *word, unsigned size);
int Authe_Hex(char *word, unsigned size);
int Authe_Dec(char* word, unsigned size);
int Authe_Instr(char* word, unsigned size);
int Authe_Name(char* word, unsigned size);
int Authe_Line();

/* 
 * Argumentos:
 *  entrada: cadeia de caracteres com o conteudo do arquivo de entrada.
 *  tamanho: tamanho da cadeia.
 * Retorna:
 *  1 caso haja erro na montagem; 
 *  0 caso não haja erro.
 */
int processarEntrada(char* entrada, unsigned tamanho){

  unsigned line = 1, in_word = 0, end_word, size_word, comment_control = 1;
  unsigned i, j, aux;
  int teste;
  char *word;
  Token token;
  
  for (i = 0; i < tamanho; i++){
     
    if (((entrada[i] == 32) || entrada[i] == 10 || entrada[i] == 9 || entrada[i] == 34) && comment_control){  // Verifica posição i == " " || i == "\n" || i == "\t" || i == """ para detectar uma palavra
     
      end_word = i;
      size_word = end_word - in_word;    

      if(size_word){
        word = malloc(size_word * sizeof(char));

        for(aux = 0; aux < size_word; in_word++, aux++)
          word[aux] = entrada[in_word];
        word[size_word] = 00;

        if(word[0] == 35){ // Def Comentario -> word[0] == "#"
          comment_control = 0; // Setando comment_control = 0, o for roda somente comparando se entrada[i] == "\n" e não analisa caracteres entre o # e \n
        }else if(word[size_word - 1] == 58){ // Def Rotulo -> word[final] == ":"
          if(Authe_DefLabel(word, size_word)){
            fprintf(stderr, "%s %d!\n", "ERRO LEXICO: palavra inválida na linha", line);
            return 1;
          }else{
            token.tipo = DefRotulo;
            token.palavra = word;
            token.linha = line;
            adicionarToken(token);
          }
        }else if(word[0] == 46){ // Def Diretiva -> word[0] == "."
          if(Authe_Directive(word, size_word)){
            fprintf(stderr, "%s %d!\n", "ERRO LEXICO: palavra inválida na linha", line);
            return 1;
          }else{
            token.tipo = Diretiva;
            token.palavra = word;
            token.linha = line;
            adicionarToken(token);
          }
        }else if(word[0] == 48 && word[1] == 120 && (size_word == 12)){ // Hex word[0] == 0 e word[1] == x
          if(Authe_Hex(word, size_word)){
            fprintf(stderr, "%s %d!\n", "ERRO LEXICO: palavra inválida na linha", line);
            return 1;
          }else{
            token.tipo = Hexadecimal;
            token.palavra = word;
            token.linha = line;
            adicionarToken(token);
          }
        }else if((word[0] > 47 && word[0] < 58)){ // Dec word[0] = num
          if(Authe_Dec(word, size_word)){
            fprintf(stderr, "%s %d!\n", "ERRO LEXICO: palavra inválida na linha", line);
            return 1;
          }else{
            token.tipo = Decimal;
            token.palavra = word;
            token.linha = line;
            adicionarToken(token);
          }
        }else if(!Authe_Instr(word, size_word)){ //Verifica instrução
          token.tipo = Instrucao;
          token.palavra = word;
          token.linha = line;
          adicionarToken(token);
        }else if(!Authe_Name(word, size_word)){ //Verifica Nome
          token.tipo = Nome;
          token.palavra = word;
          token.linha = line;
          adicionarToken(token);
        }else{
            fprintf(stderr, "%s %d!\n", "ERRO LEXICO: palavra inválida na linha", line);
            return 1;
        }
      }   
      in_word = i+1;
    } 
    if (entrada[i] == 10){ //Acrescenta linha caso i == "\n" e atualiza in_word
      if(Authe_Line()){ // Autentifica a linha, devido aos critérios de erro gramatical
        fprintf(stderr, "%s %d!\n", "ERRO GRAMATICAL: palavra na linha", line);
        return 1;
      }
      line++;
      in_word = i+1;
      comment_control = 1;
    }

  }
  return 0; 
}


int Authe_DefLabel(char* word, unsigned size){
  int i;

  if(word[0] >= 48 && word[0] <= 57)
    return 1;

  for(i = 1; i < size -1; i++)
    if((word[i] < 48) || (word[i] > 57 && word[i] < 65) || (word[i] > 90 && word[i] < 97) || (word[i] > 122))
      return 1;

  return 0;
}

int Authe_Directive(char* word, unsigned size){
  static char direct[5][7] = {".set",".org",".align", ".wfill", ".word"};
  int i;

  for(i = 0; i <= 5; i++)
    if(!(strcmp(word,direct[i])))
      return 0;

  return 1;
}

int Authe_Hex(char* word, unsigned size){
  int i;

  for(i = 2; i < size ; i++)
    if((word[i] < 48 || word[i] > 57) && (word[i] < 65 || word[i] > 70) && (word[i] < 97 || word[i] > 102)){
      return 1;
    }
  
  return (0);
}

int Authe_Dec(char* word, unsigned size){
  int i, count = 0;

  for(i = 0; i < size ; i++){
    if((word[i] < 48 || word[i] > 57))
      return 1;
  }
  return 0;
}

int Authe_Instr(char* word, unsigned size){
  static char Instructions[17][10] = {"LOAD","LOAD-","LOAD|","LOADmq","LOADmq_mx","STOR","JUMP","JMP+","ADD","ADD|","SUB","SUB|","MUL","DIV","LSH","RSH","STORA"};
  int i;

  for(i = 0; i < 18; i++)
    if(!(strcmp(word,Instructions[i])))
      return 0;
  return 1;
}

int Authe_Name(char* word, unsigned size){
  int i;

  if(word[0] >= 48 && word[0] <= 57)
    return 1;

  for(i = 1; i < size; i++)
    if((word[i] < 48) || (word[i] > 57 && word[i] < 65) || (word[i] > 90 && word[i] < 97) || (word[i] > 122))
      return 1;

  return 0;
}

int Authe_Line(){
  static int token_control = 0;

  Token *token;
  int i, numberOfToken;
  int size_tokens = getNumberOfTokens();

  numberOfToken = size_tokens - token_control;

  token = malloc(numberOfToken * sizeof(token));

  for(token_control, i = 0; token_control < size_tokens; i++, token_control++){
    token[i] = recuperaToken(token_control);
  }

  if(token[0].tipo == Hexadecimal || token[0].tipo == Decimal || token[0].tipo == Nome){  // Ve se a primeira palavra da linha não é Hex, Dec, Nome
    return 1;
  }else if(numberOfToken == 1){  //Linha somente com rotulo
    if(token[0].tipo == DefRotulo){
      return 0;
    }else if(token[0].tipo == Instrucao){  // Linha iniciada com intrução sozinha
      if(!(strcmp(token[0].palavra, "RSH")) || !(strcmp(token[0].palavra, "LOADmq")) || !(strcmp(token[0].palavra, "LSH"))){ //valida caso as instruções sejam LSH,LOADmq,RSH
        return 0;
      }else{
        return 1;
      }
    }else{ // Diretiva sozinha = erro gramatical // Todas as Diretivas necessitam de pelo menos um Argumento
      return 1;
    }
  }else { // Caso numero de tokens > 1

    for(i = 0; i < numberOfToken - 1; i++){  // Percorre Lista de Tokens da Linha
      if(token[i].tipo == DefRotulo){    // Caso inicie com rotulo
        if(token[i+1].tipo != Instrucao && token[i+1].tipo != Diretiva)  // Verifica se o proximo token é Diretiva ou Instrução, caso não for a linha é invalida
          return 1;
      }else if(token[i].tipo == Instrucao){  // Caso instrução
        if(numberOfToken > i+2) // Verifica se não há mais de 1 Argumento na linha
          return 1;
        if(numberOfToken == i+1) // Caso não tenha argumentos na linha
          if(!(strcmp(token[0].palavra, "RSH")) || !(strcmp(token[0].palavra, "LOADmq")) || !(strcmp(token[0].palavra, "LSH"))) // Se n for LSH, LOADmq, RSH -> linha invalida
            return 1;
        if(numberOfToken < i+1) // Linha com 1 Argumento
          if((strcmp(token[0].palavra, "RSH")) && (strcmp(token[0].palavra, "LOADmq")) && (strcmp(token[0].palavra, "LSH"))) // Se for LSH, LOADmq, RSH -> linha invalida
            return 1;
        if(token[i+1].tipo != Nome && token[i+1].tipo != Decimal && token[i+1].tipo != Hexadecimal) // Caso Argumento não seja Hex, Dec, Nome -> linha invalida
          return 1;
      }else if(token[i].tipo == Diretiva){

        if(!(strcmp(token[i].palavra, ".set"))){ // Caso diretiva .set
          if(numberOfToken > i+3) // Caso tenha mais de 2 argumentos -> linha invalida
            return 1;
          if(numberOfToken < i+2) // Caso tenha 1 Argumento -> linha invalida
            return 1;
          if(token[i+1].tipo != Nome || (token[i+2].tipo != Hexadecimal && token[i+2].tipo != Decimal)) // Arg[1] != Nome e (Arg[2] != Hex ou Arg[2] != Dec) -> linha invalida
            return 1;
        }

        if(!(strcmp(token[i].palavra, ".org"))){ // Diretiva .org
          if(numberOfToken > i+2) // Caso tenha 2 Argumentos -> linha invalida
            return 1;
          if(numberOfToken < i+1) // Caso não tenha Argumentos -> linha invalida
            return 1;
          if(token[i+1].tipo != Decimal && token[i+1].tipo != Hexadecimal) // Caso Argumento seja diferente de Hex, Dec -> linha invalida
            return 1;
          if(token[i+1].tipo == Decimal) // Verifica limite do Decimal
            if(token[i+1].palavra[0] == 45)
              return 1;
        }

        if(!(strcmp(token[i].palavra, ".align"))){ //Diretiva .align
          if(numberOfToken > i+2) // Caso tenha 2 Argumentos -> linha invalida
            return 1;
          if(numberOfToken < i+1) // Caso não tenha Argumentos -> linha invalida
            return 1;
          if(token[i+1].tipo != Decimal) // Caso Argumento seja diferente de Decimal -> linha invalida
            return 1;
          else if(token[i+1].palavra[0] == 45 || token[i+1].palavra[0] == 48) //Verifica intervalo do Decimal
            return 1;
        }

        if(!(strcmp(token[i].palavra, ".wfill"))){
          if(numberOfToken > i+3) // Caso tenha mais de 2 argumentos -> linha invalida
            return 1;
          if(numberOfToken < i+2) // Caso tenha 1 Argumento -> linha invalida
            return 1;
          if(token[i+1].tipo != Decimal) // Verifica se Arg[1] é Decimal, se não -> linha invalida
            return 1; 
          else if(token[i+1].palavra[0] == 45 || token[i+1].palavra[0] == 48) // Verifica intervalo do Decimal
            return 1;
          if(token[i+2].tipo != Decimal && token[i+2].tipo != Hexadecimal && token[i+2].tipo != Nome) // Verifica se Arg[2] é Dec, Hexa, Nome, se não -> linha invalida
            return 1;
        }
        
        if(!(strcmp(token[i].palavra, ".word"))){
          if(numberOfToken > i+2) // Caso tenha 2 Argumentos -> linha invalida
            return 1;
          if(numberOfToken <  i+1) // Caso não tenha argumento -> linha invalida
            return 1;
          if(token[i+1].tipo != Decimal && token[i+1].tipo != Hexadecimal && token[i+1].tipo != Nome) // Verifica se Arg é Dec, Hex, Nome, se não -> linha invalida
            return 1;
        }
      }
    }
  }
  return 0;
}