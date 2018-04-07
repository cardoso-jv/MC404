#include "montador.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


typedef struct Linked_List{
  int flag; // 0 - simb || 1 - rot
  char *word;
  int pc_count;
  int side; // 0 - esq || 1 - dir
  int num;
} Name;


int* get_digits(int *v, int num);
int indentify_instruction(Token token, int *op);
int indentify_directive(Token token);
int search_multiple(int pc, int m);
int search_Name(Name *list, int size, char *word);
int verify_error(int S, int PC, int M[][6]);
int search_Label(int num, int M[][6], int line);
void print_MemMap(int S, int M[][6], int line);
void search_DuplicatedName(Name *list, int size);



/* Retorna:
 *  1 caso haja erro na montagem; 
 *  0 caso não haja erro.
 */

int emitirMapaDeMemoria(){
  Name *list_name;
  Token auxTok[4];
  int M[1024][6];
  char word[64];
  int PC = 0, S = 0, line = 0, TypeOfInst;
  int i,j, numOfTok, posTok = 0, iName = 0;
  int op, *v;
  int aux, aux2;


  numOfTok = getNumberOfTokens();

  list_name = malloc(numOfTok * sizeof(Name));
  v = malloc(4 * sizeof(int));
 

  do{
    auxTok[0] = recuperaToken(posTok);
    switch(auxTok[0].tipo){
      
      case 0: // Instrução
        if(!S) // Esq
          S = 1;
        else{ // Dir
          line++;
          S = 0;
          PC++;
        }
        break;

      case 1: // Diretiva
        switch(indentify_directive(auxTok[0])){
          case 0: // .set
            auxTok[1] = recuperaToken(posTok+1);
            auxTok[2] = recuperaToken(posTok+2);

            if(auxTok[2].tipo == 3){ // HEXA
              list_name[iName].flag = 0;
              list_name[iName].word = auxTok[1].palavra;
              sscanf(auxTok[2].palavra, "0x%X", &list_name[iName].num);
              iName++;
            }

            if(auxTok[2].tipo == 4){ // DEC
              list_name[iName].flag = 0;
              list_name[iName].word = auxTok[1].palavra;
              sscanf(auxTok[2].palavra, "%d", &list_name[iName].num);
              iName++;
            }
            break;

          case 1: // .org
            auxTok[1] = recuperaToken(posTok+1);        

            if(auxTok[1].tipo == 3){ // HEXA
              sscanf(auxTok[1].palavra, "0x%x", &PC);  
              S = 0;
            }
            if(auxTok[1].tipo == 4){ // DEC
              sscanf(auxTok[1].palavra, "%d", &PC);
              S = 0;
            }
            break;

          case 2: // .align
            auxTok[1] = recuperaToken(posTok+1);  // DECIMAL
            sscanf(auxTok[1].palavra, "%d", &aux);  
            PC = search_multiple(PC,aux);
            S = 0;
            break;
        
          case 3: // .wfill
            auxTok[1] = recuperaToken(posTok+1);
            sscanf(auxTok[1].palavra, "%d", &aux);  
            for(i = 0; i < aux; i++){
              line++;
              PC++;
            }
            break;
        
          case 4: // .word  
            auxTok[1] = recuperaToken(posTok+1);
            line ++;
            PC++;
            break;       
        }
      
      case 2: // DefRotulo
        list_name[iName].flag = 1;
        aux = strlen(auxTok[0].palavra);
        for(i = 0; i < aux; i++){
          if(auxTok[0].palavra[i] == 58){
            auxTok[0].palavra[i] = '\0';
          }
          word[i] = auxTok[0].palavra[i];
        }
        word[i] = '\0';  
        list_name[iName].word = word;
        list_name[iName].pc_count = PC;
        list_name[iName].side = S;
        iName++;
        break;

    }

    posTok++;

  } while (posTok < numOfTok);

  for(i = 0; i < 1024; i++){
    M[i][0] = -1;
    for(j = 1; j < 6; j++){
      M[i][j] = 0;
    }
  }


  posTok = 0;
  PC = 0;
  line = 0;
  S = 0;


  search_DuplicatedName(list_name, iName);
  
  do{
    auxTok[0] = recuperaToken(posTok);
    switch(auxTok[0].tipo){
      case 0: // Instrução
        TypeOfInst = indentify_instruction(auxTok[0], &op);
        if(!S){ // Esq
          verify_error(S, PC, M);
          if(TypeOfInst == 0){   // CASO GERAL
            auxTok[1] = recuperaToken(posTok+1); 
            if(auxTok[1].tipo == 3){ // Hexa
              sscanf(auxTok[1].palavra, "0x%X", &aux);
              M[line][0] = PC;
              M[line][1] = op;
              M[line][2] = aux;               
            }
            if(auxTok[1].tipo == 4){ // Dec
              sscanf(auxTok[1].palavra, "%d", &aux); 
              M[line][0] = PC;
              M[line][1] = op;
              M[line][2] = aux; 
            } 
            if(auxTok[1].tipo == 5){ // Nome
              aux = search_Name(list_name, iName, auxTok[1].palavra);
              if(list_name[aux].flag == 0){ // Simb
                M[line][0] = PC;
                M[line][1] = op;
                M[line][2] = list_name[aux].num;
              }else{  // Rotulo
                M[line][0] = PC;
                M[line][1] = op;
                M[line][2] = list_name[aux].pc_count;
              }
            }
          }else if(TypeOfInst == 1){  // LOADmq || LSH || RSH
            M[line][0] = PC;
            M[line][1] = op;
            M[line][2] = 0;
          }else if(TypeOfInst == 2){  // JUMP || JMP+ || STORA  
            auxTok[1] = recuperaToken(posTok+1);
            if(auxTok[1].tipo == 3){ // Hexa
              sscanf(auxTok[1].palavra, "0x%X", &aux);   
              M[line][0] = PC;
              M[line][1] = op;
              M[line][2] = aux;               
            }
            if(auxTok[1].tipo == 4){ // Dec
              sscanf(auxTok[1].palavra, "%d", &aux);
              M[line][0] = PC;
              M[line][1] = op;
              M[line][2] = aux; 
            } 
            if(auxTok[1].tipo == 5){ // Nome
              aux = search_Name(list_name, iName, auxTok[1].palavra);
              if(list_name[aux].flag == 0){ // Simb
                M[line][0] = PC;
                M[line][1] = op;
                M[line][2] = list_name[aux].num;
              }else{  // Rotulo
                if(list_name[aux].side == 0){ // ESQ
                  M[line][0] = PC;
                  M[line][1] = op;
                  M[line][2] = list_name[aux].pc_count;
                }else{ // DIR
                  M[line][0] = PC;
                  M[line][1] = op+1;
                  M[line][2] = list_name[aux].pc_count;
                }
              }
            }
          }

          S = 1;
        }else{ // Dir
          if(TypeOfInst == 0){   // CASO GERAL
            auxTok[1] = recuperaToken(posTok+1);
            if(auxTok[1].tipo == 3){ // Hexa
              sscanf(auxTok[1].palavra, "0x%X", &aux);   
              M[line][3] = op;
              M[line][4] = aux;               
            }
            if(auxTok[1].tipo == 4){ // Dec
              sscanf(auxTok[1].palavra, "%d", &aux);    
              M[line][3] = op;
              M[line][4] = aux; 
            } 
            if(auxTok[1].tipo == 5){ // Nome
              aux = search_Name(list_name, iName, auxTok[1].palavra);
              if(list_name[aux].flag == 0){ // Simb
                M[line][3] = op;
                M[line][4] = list_name[aux].num;
              }else{  // Rotulo
                M[line][3] = op;
                M[line][4] = list_name[aux].pc_count;
              }
            }
          }else if(TypeOfInst == 1){  // LOADmq || LSH || RSH 
            M[line][3] = op;
            M[line][4] = 0;
          }else if(TypeOfInst == 2){  // JUMP || JMP+ || STORA  
            auxTok[1] = recuperaToken(posTok+1);
            if(auxTok[1].tipo == 3){ // Hexa
              sscanf(auxTok[1].palavra, "0x%X", &aux);   
              M[line][3] = op;
              M[line][4] = aux;               
            }
            if(auxTok[1].tipo == 4){ // Dec
              sscanf(auxTok[1].palavra, "%d", &aux);    
              M[line][3] = op;
              M[line][4] = aux; 
            }
            if(auxTok[1].tipo == 5){ // Nome
              aux = search_Name(list_name, iName, auxTok[1].palavra);
              if(list_name[aux].flag == 0){ // Simb
                M[line][3] = op;
                M[line][4] = list_name[aux].num;
              }else{  // Rotulo
                if(list_name[aux].side == 0){ // ESQ
                  M[line][3] = op;
                  M[line][4] = list_name[aux].pc_count;
                }else{  // DIR
                  M[line][3] = op+1;
                  M[line][4] = list_name[aux].pc_count;
                }
              }
            }             
          }      
          line++;
          S = 0;
          PC++;
        }
        break;

      case 1: // Diretiva
        switch(indentify_directive(auxTok[0])){
          case 1: // .org
            auxTok[1] = recuperaToken(posTok+1);        
            if(auxTok[1].tipo == 3){ // HEXA
              sscanf(auxTok[1].palavra, "0x%X", &aux);   
              PC = aux;
              S = 0;
            }
            if(auxTok[1].tipo == 4){ // DEC
              sscanf(auxTok[1].palavra, "%d", &aux);   
              PC = aux;
              S = 0;
            }
            break;
          case 2: // .align
            auxTok[1] = recuperaToken(posTok+1);  // DECIMAL
            sscanf(auxTok[1].palavra, "%d", &aux);   
            PC = search_multiple(PC,aux);
            S = 0;
            break;
          case 3: // .wfill
            verify_error(S, PC, M);
            auxTok[1] = recuperaToken(posTok+1);
            auxTok[2] = recuperaToken(posTok+2);
            if(auxTok[2].tipo == 3){ // Hexa
              sscanf(auxTok[2].palavra, "0x%X", &aux);
              v = get_digits(v, aux);
              sscanf(auxTok[1].palavra, "%d", &aux2);                 
              for(i = 0; i < aux2; i++){
                M[line][0] = PC;
                M[line][1] = v[0];
                M[line][2] = v[1];
                M[line][3] = v[2];
                M[line][4] = v[3];
                line++;
                PC++;
              } 
            }
            if(auxTok[2].tipo == 4){ // Dec
              sscanf(auxTok[2].palavra, "%d", &aux);                                           
              v = get_digits(v, aux);
              sscanf(auxTok[1].palavra, "%d", &aux2);                             
              for(i = 0; i < aux2; i++){
                M[line][0] = PC;
                M[line][1] = v[0];
                M[line][2] = v[1];
                M[line][3] = v[2];
                M[line][4] = v[3];
                line++;
                PC++;
              }
            }
            if(auxTok[2].tipo == 5){ // Nome
                aux = search_Name(list_name, iName, auxTok[2].palavra);
                if(list_name[aux].flag == 0){ // Simb
                  v = get_digits(v, list_name[aux].num);
                  sscanf(auxTok[1].palavra, "%d", &aux2);                             
                  for(i = 0; i < aux2; i++){                  
                    M[line][0] = PC;
                    M[line][1] = v[0];
                    M[line][2] = v[1];
                    M[line][3] = v[2];
                    M[line][4] = v[3];
                    line++;
                    PC++;
                  }
                }else{  // Rotulo
                  v = get_digits(v, list_name[aux].pc_count);
                  sscanf(auxTok[1].palavra, "%d", &aux2);                             
                  for(i = 0; i < aux2; i++){
                    M[line][0] = PC;
                    M[line][1] = v[0];
                    M[line][2] = v[1];
                    M[line][3] = v[2];
                    M[line][4] = v[3];
                    line++;
                    PC++;
                  }
                }
              }
            break;
          case 4: // .word 
            verify_error(S, PC, M);
            auxTok[1] = recuperaToken(posTok+1);
            M[line][0] = PC;
            if(auxTok[1].tipo == 3){ // Hexa
              sscanf(auxTok[1].palavra, "0x%X", &aux);              
              v = get_digits(v, aux);
              M[line][1] = v[0];
              M[line][2] = v[1];
              M[line][3] = v[2];
              M[line][4] = v[3];
              line++;
              PC++;
            }
            if(auxTok[1].tipo ==  4){ // Decimal
              sscanf(auxTok[1].palavra, "%d", &aux);  
              v = get_digits(v, aux);
              M[line][1] = v[0];
              M[line][2] = v[1];
              M[line][3] = v[2];
              M[line][4] = v[3];
              line ++;
              PC++;
            }
            if(auxTok[1].tipo == 5){ // Nome
              aux = search_Name(list_name, iName, auxTok[1].palavra);
              if(list_name[aux].flag == 0){ // Simb
                v = get_digits(v, list_name[aux].num);
                M[line][1] = v[0];
                M[line][2] = v[1];
                M[line][3] = v[2];
                M[line][4] = v[3];
                line++;
                PC++;
              }else{  // Rotulo
                v = get_digits(v, list_name[aux].pc_count);
                M[line][1] = v[0];
                M[line][2] = v[1];
                M[line][3] = v[2];
                M[line][4] = v[3];
                line++;
                PC++;
              }
            }
            break;   
        }
    }   
    

  posTok++;

} while (posTok < numOfTok);

  
  print_MemMap(S, M, line);

  
  return 0;

}

int indentify_directive(Token token){
  static char Direct[5][7] = {".set",".org",".align", ".wfill", ".word"};
  int i;

  for(i = 0; i <= 5; i++)
    if(!(strcmp(token.palavra,Direct[i])))
      return i;
}

int search_multiple(int pc, int m){
  while(pc%m)
    pc++;
  
  return pc;
}

int* get_digits(int *v, int num){
  int r1,r2,r3,d1,d2,d3,d4;

  r1 = num % 4294967296;
  r2 = num % 1048576;
  r3 = num % 4096;
  
  d1 = num / 4294967296;
  d2 = r1 / 1048576;
  d3 = r2 / 4096;
  d4 = r3;

  v[0] = d1;
  v[1] = d2;
  v[2] = d3;
  v[3] = d4;
  return v;
}

int verify_error(int S, int PC, int M[][6]){
  int i,j;

  if(S || PC > 1023){
    fprintf(stderr, "%s\n", "Impossível montar o código!");
    exit(1);
  }

  for(i = 0; i < 1024; i++){
    if(M[i][0] == PC){
      fprintf(stderr, "%s\n", "Impossível montar o código!");
      exit(1);
    }
  }
}

int indentify_instruction(Token token, int *op){
  static char Instructions[17][10] = {"LOAD","LOAD-","LOAD|","LOADmq","LOADmq_mx","STOR","JUMP","JMP+","ADD","ADD|","SUB","SUB|","MUL","DIV","LSH","RSH","STORA"};
  static int OP_Instructions[17] = {0x01,0x02,0x03,0x0A,0x09,0x21,0x0D,0x0F,0x05,0x07,0x06,0x08,0x0B,0x0C,0x14,0x15,0x12};
  int i;

  for (i = 0; i < 17; i++){
    if(!(strcmp(token.palavra,Instructions[i]))){
      *op = OP_Instructions[i];
      if(i == 3 || i == 14 || i == 15)
        return 1;
      else if(i == 6 || i == 7 || i == 16)
        return 2;
      else
        return 0; 
    }
  }
}

void print_MemMap(int S, int M[][6], int line){
  int i, j;

  if(S){
    for(i = 0; i <= line; i++){
      for(j = 0; j < 5; j++){
        if(!(j%2))
          printf("%03X",M[i][j]);
        if(j%2)
          printf(" %02X ",M[i][j]);
      }
      printf("\n");
    }
  }else{
    for(i = 0; i < line; i++){
      for(j = 0; j < 5; j++){
        if(!(j%2))
          printf("%03X",M[i][j]);
        if(j%2)
          printf(" %02X ",M[i][j]);
      }
      printf("\n");
    }    
  }
}

int search_Name(Name *list, int size, char *word){
  int i;
  for(i = 0; i < size; i++){
    if(!(strcmp(list[i].word,word))){
      return i;
    }
  }
  fprintf(stderr, "%s %s!\n", "USADO MAS NÃO DEFINIDO:", word);
  exit(1);
  
}

void search_DuplicatedName(Name *list, int size){
  int i, j;
  for(i = 0; i < size; i++){    
    for(j = size; j < size; j++){
      if(!(strcmp(list[i].word,list[j].word)) && (i != j)){
        fprintf(stderr, "%s\n", "Impossível montar o código!");
        exit(1);
      }
    }
  }
}

int search_Label(int num, int M[][6], int line){
  int i;
  for(i = 0; i <= line; i++){
    if(M[i][0] == num){
      return i;
    }
  }
}
