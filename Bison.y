%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

extern int yylex();
void yyerror(const char *s);

/* --- DATABASE STORAGE ENGINE (In-Memory) --- */

#define MAX_TABLES 5
#define MAX_COLS 10
#define MAX_ROWS 50
#define LEN 50

typedef struct {
    char name[LEN];
    char type[LEN];
} Column;

typedef struct {
    char values[MAX_COLS][LEN];
} Row;

typedef struct {
    char name[LEN];
    Column columns[MAX_COLS];
    Row rows[MAX_ROWS];
    int col_count;
    int row_count;
} Table;

Table db[MAX_TABLES];
int table_count = 0;

/* Global parsing vars */
char temp_col_names[MAX_COLS][LEN];
int temp_col_count = 0;
char temp_values[MAX_COLS][LEN];
int temp_val_count = 0;

/* --- HELPER FUNCTIONS --- */

int find_table(char *name) {
    for(int i=0; i<table_count; i++) {
        if(strcmp(db[i].name, name) == 0) return i;
    }
    return -1;
}

int find_col(Table *t, char *col_name) {
    for(int i=0; i<t->col_count; i++) {
        if(strcmp(t->columns[i].name, col_name) == 0) return i;
    }
    return -1;
}

/* Helper to print table separators: +----------+ */
void print_separator(int cols) {
    printf("+");
    for(int i=0; i<cols; i++) printf("----------+");
    printf("\n");
}

/* --- COMMAND IMPLEMENTATIONS --- */

void create_table(char *name) {
    if(table_count >= MAX_TABLES) { printf("Error: DB Full\n"); return; }
    strcpy(db[table_count].name, name);
    db[table_count].col_count = temp_col_count;
    db[table_count].row_count = 0;
    for(int i=0; i<temp_col_count; i++) strcpy(db[table_count].columns[i].name, temp_col_names[i]);
    table_count++;
    printf("[OK] Table '%s' created.\n", name);
    temp_col_count = 0;
}

void insert_row(char *table_name) {
    int t_idx = find_table(table_name);
    if(t_idx == -1) { printf("Error: Table not found\n"); return; }
    Table *t = &db[t_idx];
    for(int i=0; i<temp_val_count && i<t->col_count; i++) strcpy(t->rows[t->row_count].values[i], temp_values[i]);
    t->row_count++;
    printf("[OK] 1 row inserted into '%s'.\n", table_name);
    temp_val_count = 0;
}

void execute_update(char *table_name, char *set_col, char *set_val, char *where_col, char *where_val) {
    int t_idx = find_table(table_name);
    if(t_idx == -1) { printf("Error: Table not found\n"); return; }
    Table *t = &db[t_idx];
    int s_idx = find_col(t, set_col);
    int w_idx = find_col(t, where_col);
    if(s_idx == -1 || w_idx == -1) { printf("Error: Column not found\n"); return; }

    int updated = 0;
    for(int r = 0; r < t->row_count; r++) {
        if(strcmp(t->rows[r].values[w_idx], where_val) == 0) {
            strcpy(t->rows[r].values[s_idx], set_val);
            updated++;
        }
    }
    printf("[OK] %d row(s) updated in '%s'.\n", updated, table_name);
}

void execute_delete(char *table_name, char *col_name, char *val) {
    int t_idx = find_table(table_name);
    if(t_idx == -1) { printf("Error: Table not found\n"); return; }
    Table *t = &db[t_idx];
    int c_idx = find_col(t, col_name);
    if(c_idx == -1) { printf("Error: Column not found\n"); return; }

    int deleted = 0;
    for(int r = t->row_count - 1; r >= 0; r--) {
        if(strcmp(t->rows[r].values[c_idx], val) == 0) {
            for(int k = r; k < t->row_count - 1; k++) t->rows[k] = t->rows[k+1];
            t->row_count--;
            deleted++;
        }
    }
    printf("[OK] %d row(s) deleted from '%s'.\n", deleted, table_name);
}

/* --- SELECT WITH LOGIC (AND/OR) --- */
void execute_select_logic(char *table_name, char *c1, char *op1, char *v1, char *logic, char *c2, char *op2, char *v2) {
    int t_idx = find_table(table_name);
    if(t_idx == -1) { printf("Error: Table not found\n"); return; }
    Table *t = &db[t_idx];
    int idx1 = find_col(t, c1);
    int idx2 = find_col(t, c2);

    printf("\nFILTERED RESULTS:\n");
    print_separator(t->col_count);
    printf("|");
    for(int i=0; i<t->col_count; i++) printf(" %-8s |", t->columns[i].name);
    printf("\n");
    print_separator(t->col_count);

    for(int r=0; r<t->row_count; r++) {
        int match1 = (strcmp(t->rows[r].values[idx1], v1) == 0);
        int match2 = (strcmp(t->rows[r].values[idx2], v2) == 0);
        int final_match = (strcmp(logic, "AND") == 0) ? (match1 && match2) : (match1 || match2);

        if(final_match) {
            printf("|");
            for(int c=0; c<t->col_count; c++) printf(" %-8s |", t->rows[r].values[c]);
            printf("\n");
        }
    }
    print_separator(t->col_count);
    printf("\n");
}

/* --- JOINS (LEFT / RIGHT) - UPDATED TO HIDE DUPLICATE ID --- */
void execute_join(int mode, char *t1_name, char *t2_name, char *c1, char *c2) {
    int t1_idx = find_table(t1_name);
    int t2_idx = find_table(t2_name);
    if(t1_idx == -1 || t2_idx == -1) { printf("Error: Table not found\n"); return; }
    Table *A = &db[t1_idx];
    Table *B = &db[t2_idx];
    int c1_idx = find_col(A, c1);
    int c2_idx = find_col(B, c2);

    printf("\nJOIN RESULT (%s %s JOIN %s):\n", t1_name, (mode==1?"LEFT":"RIGHT"), t2_name);
    
    // Calculate total columns minus 1 (hiding duplicate join column)
    int total_cols = A->col_count + B->col_count - 1;
    
    print_separator(total_cols);
    printf("|");
    // Print Table A headers
    for(int i=0; i<A->col_count; i++) printf(" %-8s |", A->columns[i].name);
    // Print Table B headers (SKIP if name matches join column)
    for(int i=0; i<B->col_count; i++) {
        if(strcmp(B->columns[i].name, c2) == 0) continue; 
        printf(" %-8s |", B->columns[i].name);
    }
    printf("\n");
    print_separator(total_cols);

    if(mode == 1) { // LEFT JOIN
        for(int i=0; i<A->row_count; i++) {
            int matched = 0;
            for(int j=0; j<B->row_count; j++) {
                if(strcmp(A->rows[i].values[c1_idx], B->rows[j].values[c2_idx]) == 0) {
                    printf("|");
                    for(int k=0; k<A->col_count; k++) printf(" %-8s |", A->rows[i].values[k]);
                    // Print B values (SKIP join col)
                    for(int k=0; k<B->col_count; k++) {
                        if(strcmp(B->columns[k].name, c2) == 0) continue;
                        printf(" %-8s |", B->rows[j].values[k]);
                    }
                    printf("\n");
                    matched = 1;
                }
            }
            if(!matched) {
                printf("|");
                for(int k=0; k<A->col_count; k++) printf(" %-8s |", A->rows[i].values[k]);
                // Print NULLs for B (SKIP join col)
                for(int k=0; k<B->col_count; k++) {
                    if(strcmp(B->columns[k].name, c2) == 0) continue;
                    printf(" %-8s |", "NULL");
                }
                printf("\n");
            }
        }
    }
    else { // RIGHT JOIN
        for(int j=0; j<B->row_count; j++) {
            int matched = 0;
            for(int i=0; i<A->row_count; i++) {
                if(strcmp(A->rows[i].values[c1_idx], B->rows[j].values[c2_idx]) == 0) {
                    printf("|");
                    for(int k=0; k<A->col_count; k++) printf(" %-8s |", A->rows[i].values[k]);
                    // Print B values (SKIP join col)
                    for(int k=0; k<B->col_count; k++) {
                        if(strcmp(B->columns[k].name, c2) == 0) continue;
                        printf(" %-8s |", B->rows[j].values[k]);
                    }
                    printf("\n");
                    matched = 1;
                }
            }
            if(!matched) {
                printf("|");
                for(int k=0; k<A->col_count; k++) printf(" %-8s |", "NULL");
                // Print B values (SKIP join col)
                for(int k=0; k<B->col_count; k++) {
                    if(strcmp(B->columns[k].name, c2) == 0) continue;
                    printf(" %-8s |", B->rows[j].values[k]);
                }
                printf("\n");
            }
        }
    }
    print_separator(total_cols);
    printf("\n");
}

/* --- AGGREGATES --- */
void execute_aggregate(int type, char *table_name, char *col_name) {
    int t_idx = find_table(table_name);
    if(t_idx == -1) { printf("Error: Table not found\n"); return; }
    Table *t = &db[t_idx];
    int c_idx = find_col(t, col_name);
    
    double sum = 0;
    for(int i=0; i<t->row_count; i++) sum += atof(t->rows[i].values[c_idx]);

    printf("\n+----------+\n");
    if(type == 1) printf("| COUNT    |\n+----------+\n| %-8d |\n", t->row_count);
    if(type == 2) printf("| SUM      |\n+----------+\n| %-8.2f |\n", sum);
    if(type == 3) printf("| AVERAGE  |\n+----------+\n| %-8.2f |\n", t->row_count?sum/t->row_count:0);
    printf("+----------+\n\n");
}

void show_table(char *table_name) {
    int t_idx = find_table(table_name);
    if(t_idx == -1) { printf("Error: Table not found\n"); return; }
    Table *t = &db[t_idx];
    printf("\nTABLE: %s\n", table_name);
    print_separator(t->col_count);
    printf("|");
    for(int i=0; i<t->col_count; i++) printf(" %-8s |", t->columns[i].name);
    printf("\n");
    print_separator(t->col_count);
    for(int r=0; r<t->row_count; r++) {
        printf("|");
        for(int c=0; c<t->col_count; c++) printf(" %-8s |", t->rows[r].values[c]);
        printf("\n");
    }
    print_separator(t->col_count);
    printf("(%d rows)\n\n", t->row_count);
}
%}

%union { int int_val; float float_val; char *str_val; } 
%token CREATE DATABASE TABLE DROP SELECT INSERT INTO VALUES UPDATE DELETE
%token FROM WHERE ORDER BY GROUP HAVING JOIN INNER LEFT RIGHT FULL ON SET
%token AND OR NOT NULL_TOKEN COUNT SUM AVG MIN MAX AS ASC DESC
%token INT_TYPE VARCHAR CHAR_TYPE FLOAT_TYPE DATE BOOLEAN
%token PRIMARY KEY FOREIGN REFERENCES UNIQUE DEFAULT
%token <int_val> INTEGER
%token <float_val> FLOAT
%token <str_val> ID STRING
%token EQ NEQ LT LTE GT GTE PLUS MINUS MULTIPLY DIVIDE
%token COMMA SEMICOLON LPAREN RPAREN DOT
%type <str_val> column_name table_name value literal data_type constraints 
%left OR
%left AND

%%

program: | program statement SEMICOLON ;

statement:
    create_database_stmt | create_table_stmt | drop_table_stmt | insert_stmt | select_stmt | join_stmt | agg_stmt | update_stmt | delete_stmt ;

create_database_stmt: CREATE DATABASE ID { printf("[OK] Database '%s' created.\n", $3); free($3); } ;
create_table_stmt: CREATE TABLE table_name LPAREN column_definitions RPAREN { create_table($3); free($3); } ;
insert_stmt: INSERT INTO table_name VALUES LPAREN value_list RPAREN { insert_row($3); free($3); } ;

select_stmt:
    SELECT MULTIPLY FROM table_name { show_table($4); free($4); }
    | SELECT MULTIPLY FROM table_name WHERE column_name EQ value AND column_name EQ value
      { execute_select_logic($4, $6, "=", $8, "AND", $10, "=", $12); }
    | SELECT MULTIPLY FROM table_name WHERE column_name EQ value OR column_name EQ value
      { execute_select_logic($4, $6, "=", $8, "OR", $10, "=", $12); }
    ;

agg_stmt:
    SELECT COUNT LPAREN column_name RPAREN FROM table_name { execute_aggregate(1, $7, $4); }
    | SELECT SUM LPAREN column_name RPAREN FROM table_name { execute_aggregate(2, $7, $4); }
    | SELECT AVG LPAREN column_name RPAREN FROM table_name { execute_aggregate(3, $7, $4); }
    ;

join_stmt:
    SELECT MULTIPLY FROM table_name LEFT JOIN table_name ON column_name EQ column_name
    { execute_join(1, $4, $7, $9, $11); free($4); free($7); }
    | SELECT MULTIPLY FROM table_name RIGHT JOIN table_name ON column_name EQ column_name
    { execute_join(2, $4, $7, $9, $11); free($4); free($7); }
    ;

update_stmt: UPDATE table_name SET column_name EQ value WHERE column_name EQ value { execute_update($2, $4, $6, $8, $10); } ;
delete_stmt: DELETE FROM table_name WHERE column_name EQ value { execute_delete($3, $5, $7); } ;
drop_table_stmt: DROP TABLE table_name { printf("[OK] Table dropped.\n"); } ;

/* Helpers */
table_name: ID { $$ = $1; };
column_name: ID { $$ = $1; };
column_definitions: column_definition | column_definitions COMMA column_definition ;
column_definition: column_name data_type constraints { strcpy(temp_col_names[temp_col_count++], $1); free($1); free($2); if($3) free($3); } ;
data_type: INT_TYPE { $$ = strdup("INT"); } | VARCHAR LPAREN INTEGER RPAREN { $$ = strdup("VARCHAR"); } | FLOAT_TYPE { $$ = strdup("FLOAT"); } ;
constraints: /* empty */ { $$ = NULL; } | PRIMARY KEY { $$ = strdup("PK"); } ;
value_list: value { strcpy(temp_values[temp_val_count++], $1); free($1); } | value_list COMMA value { strcpy(temp_values[temp_val_count++], $3); free($3); } ;
value: literal { $$ = $1; } ;
literal: INTEGER { char b[20]; sprintf(b, "%d", $1); $$ = strdup(b); } | FLOAT { char b[20]; sprintf(b, "%.2f", $1); $$ = strdup(b); } | STRING { $$ = $1; } ;

%%
void yyerror(const char *s) { fprintf(stderr, "Error: %s\n", s); }
int main() { printf("=== DB ENGINE ===\n"); yyparse(); return 0; }