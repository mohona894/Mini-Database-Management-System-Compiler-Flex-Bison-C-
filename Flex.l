%{
#include "db_parser2.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
%}

digit       [0-9]
integer     {digit}+
real        {digit}+\.{digit}+
letter      [a-zA-Z]
id          {letter}({letter}|{digit}|_)*
string      \'([^\']*)\'
whitespace  [ \t\n]+
comment     --.*\n

%%

"CREATE"        { return CREATE; }
"DATABASE"      { return DATABASE; }
"TABLE"         { return TABLE; }
"DROP"          { return DROP; }
"SELECT"        { return SELECT; }
"INSERT"        { return INSERT; }
"INTO"          { return INTO; }
"VALUES"        { return VALUES; }
"UPDATE"        { return UPDATE; }
"DELETE"        { return DELETE; }
"FROM"          { return FROM; }
"WHERE"         { return WHERE; }
"ORDER"         { return ORDER; }
"BY"            { return BY; }
"GROUP"         { return GROUP; }
"HAVING"        { return HAVING; }
"JOIN"          { return JOIN; }
"INNER"         { return INNER; }
"LEFT"          { return LEFT; }
"RIGHT"         { return RIGHT; }
"FULL"          { return FULL; }
"ON"            { return ON; }
"SET"           { return SET; }
"AND"           { return AND; }
"OR"            { return OR; }
"NOT"           { return NOT; }
"NULL"          { return NULL_TOKEN; }
"COUNT"         { return COUNT; }
"SUM"           { return SUM; }
"AVG"           { return AVG; }
"MIN"           { return MIN; }
"MAX"           { return MAX; }
"AS"            { return AS; }
"ASC"           { return ASC; }
"DESC"          { return DESC; }
"INT"           { return INT_TYPE; }
"VARCHAR"       { return VARCHAR; }
"CHAR"          { return CHAR_TYPE; }
"FLOAT"         { return FLOAT_TYPE; }
"DATE"          { return DATE; }
"BOOLEAN"       { return BOOLEAN; }
"PRIMARY"       { return PRIMARY; }
"KEY"           { return KEY; }
"FOREIGN"       { return FOREIGN; }
"REFERENCES"    { return REFERENCES; }
"UNIQUE"        { return UNIQUE; }
"DEFAULT"       { return DEFAULT; }

{integer}       { yylval.int_val = atoi(yytext); return INTEGER; }
{real}          { yylval.float_val = atof(yytext); return FLOAT; }
{id}            { yylval.str_val = strdup(yytext); return ID; }
{string}        { 
                    yytext[strlen(yytext)-1] = '\0';
                    yylval.str_val = strdup(yytext+1);
                    return STRING;
                }

"="             { return EQ; }
"!="            { return NEQ; }
"<"             { return LT; }
"<="            { return LTE; }
">"             { return GT; }
">="            { return GTE; }
"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return MULTIPLY; }
"/"             { return DIVIDE; }
","             { return COMMA; }
";"             { return SEMICOLON; }
"("             { return LPAREN; }
")"             { return RPAREN; }
"."             { return DOT; }

{whitespace}    { /* ignore */ }
{comment}       { printf("Comment: %s", yytext); }

.               { printf("Unknown token: %s\n", yytext); }

%%

int yywrap(void) { return 1; }