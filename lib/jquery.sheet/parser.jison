/* description: Parses end evaluates mathematical expressions. */

/* lexical grammar */
%lex
%%
\s+									{/* skip whitespace */}
'"'("\\"["]|[^"])*'"'				{return 'STRING';}
"'"('\\'[']|[^'])*"'"				{return 'STRING';}
'SHEET'[0-9]+						{return 'SHEET';}
'$'[A-Za-z]+'$'[0-9]+				{return 'FIXEDCELL';}
[A-Za-z]+[0-9]+						{return 'CELL';}
[A-Za-z]+ 							{return 'IDENTIFIER';}
[0-9]+("."[0-9]+)?  				{return 'NUMBER';}
"$"									{/* skip whitespace */}
" "									{return ' ';}
"."									{return '.';}
":"									{return ':';}
";"									{return ';';}
","									{return ',';}
"*" 								{return '*';}
"/" 								{return '/';}
"-" 								{return '-';}
"+" 								{return '+';}
"^" 								{return '^';}
"(" 								{return '(';}
")" 								{return ')';}
">" 								{return '>';}
"<" 								{return '<';}
"NOT"								{return 'NOT';}
"PI"								{return 'PI';}
"E"									{return 'E';}
'"'									{return '"';}
"'"									{return "'";}
"!"									{return "!";}
"="									{return '=';}
"%"									{return '%';}
<<EOF>>								{return 'EOF';}


/lex

/* operator associations and precedence (low-top, high- bottom) */
%left '='
%left '<=' '>=' '<>' 'NOT' '||'
%left '>' '<'
%left '+' '-'
%left '*' '/'
%left '^'
%left '%'
%left UMINUS

%start expressions

%% /* language grammar */

expressions
 : e EOF
     {return $1;}
 ;

e
	: e '=' e
		{$$ = ($1) == ($3);}
	| e '<' '=' e
		{$$ = ($1 * 1) <= ($4 * 1);}
	| e '>' '=' e
		{$$ = ($1 * 1) >= ($4 * 1);}
	| e '<' '>' e
		{$$ = ($1 * 1) != ($4 * 1);}
	| e NOT e
		{$$ = ($1 * 1) != ($3 * 1);}
	| e '>' e
		{$$ = ($1 * 1) > ($3 * 1);}
	| e '<' e
		{$$ = ($1 * 1) < ($3 * 1);}
	| e '+' e
		{
			$$ = jSE.cFN.sanitize($1) + jSE.cFN.sanitize($3); //js
			//php $$ = $1 + $3;
		}
	| e '-' e
		{$$ = ($1 * 1) - ($3 * 1);}
	| e '*' e
		{$$ = ($1 * 1) * ($3 * 1);}
	| e '/' e
		{$$ = ($1 * 1) / ($3 * 1);}
	| e '^' e
		{
			$$ = Math.pow(($1 * 1), ($3 * 1));//js
			//php $$ = pow(($1 * 1), ($3 * 1));
		}
	| '-' e
		{$$ = $2 * -1;}
	| '+' e
		{$$ = $2 * 1;}
	| '(' e ')'
		{$$ = $2;}
	| e '%'
		{$$ = $1 * 0.01;}
	
	| NUMBER
		{
			$$ = Number(yytext);//js
			//php (float)$yytext;
		}
	| E
		{
			$$ = Math.E;//js
			//php $$ = M_E;
		}
	| FIXEDCELL
		{
			$$ = yy.lexer.cellHandler.fixedCellValue.apply(yy.lexer.cell, [$1]);//js
			//php $$ = $this->fixedCellValue($1);
		}
	| FIXEDCELL ':' FIXEDCELL
		{
			$$ = yy.lexer.cellHandler.fixedCellRangeValue.apply(yy.lexer.cell, [$1, $3]);//js
			//php $$ = $this->fixedCellRangeValue($1, $3);
		}
	| CELL
		{
			$$ = yy.lexer.cellHandler.cellValue.apply(yy.lexer.cell, [$1]);//js
			//php $$ = $this->cellValue($1);
		}
	| CELL ':' CELL
		{
			$$ = yy.lexer.cellHandler.cellRangeValue.apply(yy.lexer.cell, [$1, $3]);//js
			//php $$ = $this->cellRangeValue($1, $3);
		}
	| SHEET '!' CELL
		{
			$$ = yy.lexer.cellHandler.remoteCellValue.apply(yy.lexer.cell, [$1, $3]);//js
			//php $$ = $this->remoteCellValue($1, $3);
		}
	| SHEET '!' CELL ':' CELL
		{
			$$ = yy.lexer.cellHandler.remoteCellRangeValue.apply(yy.lexer.cell, [$1, $3, $5]);//js
			//php $$ = $this->remoteCellRangeValue($1, $3, $5);
		}
	| STRING
		{
			$$ = $1.substring(1, $1.length - 1);//js
			//php $$ = substr($1, 1, -1);
		}
	| IDENTIFIER '(' ')'
		{
			$$ = yy.lexer.cellHandler.callFunction($1, '', yy.lexer.cell);//js
			//php $$ = $this->callFunction($1);
		}
	| IDENTIFIER '(' expseq ')'
		{
			$$ = yy.lexer.cellHandler.callFunction($1, $3, yy.lexer.cell);//js
			//php $$ = $this->callFunction($1, $3);
		}
 ;

expseq
 : e
	| e ';' expseq
 	{
 		$$ = ($.isArray($3) ? $3 : [$3]);//js
	 	$$.push($1);//js
		
		//php $$ = (is_array($3) ? $3 : array());
		//php $$[] = $1;
 	}
 	| e ',' expseq
	{
 		$$ = ($.isArray($3) ? $3 : [$3]);//js
	 	$$.push($1);//js
		
		//php $$ = (is_array($3) ? $3 : array());
		//php $$[] = $1;
 	}
 ;
