#
# Small C racc
#

class MyParser

rule
    program              : external_declaration
                         | program external_declaration {result = val}
    external_declaration : declaration
                         | function_prototype
                         | function_definition
    declaration          : type_specifier declarator_list ';' {result = val[0],val[1]
                                                               result.flatten!}
    declarator_list      : declarator
                         | declarator_list ',' declarator {result = val[0],val[2]}
    declarator           : direct_declarator
                         | '*' direct_declarator {result = val}
    direct_declarator  : IDENTIFIER
                       | IDENTIFIER '[' CONSTANT ']' {result = val[0], val[2]}
    function_prototype   : type_specifier function_declarator ';' {result = val[0],val[1]}
    function_declarator  : IDENTIFIER '(' parameter_type_listopt ')' {result = :none, val[0],val[2]}
                         | '*' IDENTIFIER '(' parameter_type_listopt ')' {result = val[0],val[1],val[3]}

    function_definition : type_specifier function_declarator compound_statement
                          {val[1].flatten!(1)
                           result = Function.new([val[0], val[1][0]], val[1][1], val[1][2..-1], val[2], @lineno)}
                                                 #type,               name,      arg,           contents, line
    parameter_type_list : parameter_declaration
                        | parameter_type_list ',' parameter_declaration {result = val[0],val[2]}
    parameter_declaration : type_specifier parameter_declarator {result = val.flatten!}
    parameter_declarator  : IDENTIFIER     {result = :none, val[0]}
                          | '*' IDENTIFIER {result = val}
    type_specifier       : INT
                         | VOID
    statement : ';'
              | expression ';'
              | compound_statement
              | IF '(' expression ')' statement {result = IfElse.new(val[2],val[4],:none,@lineno)}
              | IF '(' expression ')' statement ELSE statement {result = IfElse.new(val[2],val[4],val[6],@lineno)}
              | WHILE '(' expression ')' statement {result = While.new(val[2],val[4],@lineno)}
              | FOR '(' expressionopt ';' expressionopt ';' expressionopt ')' statement
                {result = val[2], While.new(val[4], [val[8],val[6]], @lineno)}
              | RETURN expressionopt ';' {result = val[0],val[1]}

    compound_statement : '{' declaration_listopt statement_listopt '}' {result = val[1],val[2]}

    declaration_list : declaration
                     | declaration_list declaration {result = val[0], val[1]}
    statement_list : statement
                   | statement_list statement {result = val[0], val[1]}
    expression : assign_expr
               | expression ',' assign_expr {result = val[0],val[2]}
    assign_expr      : logical_OR_expr
                     | logical_OR_expr '=' assign_expr {result = Assign.new(val[0], val[2], @lineno)}
    logical_OR_expr        : logical_AND_expr
                           | logical_OR_expr  '||' logical_AND_expr {result = BinExpr.new(val[0],val[1],val[2], @lineno)}
    logical_AND_expr      : equality_expr
                          | logical_AND_expr  '&&' equality_expr {result = BinExpr.new(val[0],val[1],val[2], @lineno)}
    equality_expr    : relational_expr
                     | equality_expr  '==' relational_expr {result = BinExpr.new(val[0],val[1],val[2], @lineno)}
                     | equality_expr  '!=' relational_expr {result = BinExpr.new(val[0],val[1],val[2], @lineno)}
    relational_expr    : add_expr
                       | relational_expr  '<' add_expr {result = BinExpr.new(val[0],val[1],val[2], @lineno)}
                       | relational_expr  '>' add_expr {result = BinExpr.new(val[0],val[1],val[2], @lineno)}
                       | relational_expr  '<=' add_expr {result = BinExpr.new(val[0],val[1],val[2], @lineno)}
                       | relational_expr  '>=' add_expr {result = BinExpr.new(val[0],val[1],val[2], @lineno)}
    add_expr      : mult_expr
                  | add_expr '+' mult_expr {result = BinExpr.new(val[0],val[1],val[2], @lineno)}
                  | add_expr '-' mult_expr {result = BinExpr.new(val[0],val[1],val[2], @lineno)}
    mult_expr  : unary_expr
                 | mult_expr '*' unary_expr {result = BinExpr.new(val[0],val[1],val[2], @lineno)}
                 | mult_expr '/' unary_expr {result = BinExpr.new(val[0],val[1],val[2], @lineno)}
    unary_expr  : postfix_expr
                | '-' unary_expr {result = UnaryExpr.new(val[0], val[1], @lineno)}
                | '&' unary_expr {result = UnaryExpr.new(val[0], val[1], @lineno)}
                | '*' unary_expr {result = UnaryExpr.new(val[0], val[1], @lineno)}
    postfix_expr  : primary_expr
                  | postfix_expr  '[' expression ']' {result = Arr.new(val[0],val[2],@lineno)}
                  | IDENTIFIER  '(' argument_expression_listopt ')' {result = val[0],val[2]}

    primary_expr  : IDENTIFIER
                  | CONSTANT
                  | '(' expression ')' {result = val[1]}
    argument_expression_list : assign_expr
                             | argument_expression_list ',' assign_expr {result = val[0],val[2]}

### opt
    parameter_type_listopt : parameter_type_list
                           |
    expressionopt          : expression
                           |
    declaration_listopt : declaration_list
                        |
    statement_listopt : statement_list
                      |
    argument_expression_listopt : argument_expression_list
                                |

end

---- header ----
#
# generated by racc
#
require './small_c.rex'
require 'pry'
require './class.rb'

---- inner ----
def to_tokens
  if ARGV[0]
    filename = ARGV[0]
  else
    print 'Enter filename: '
    filename = gets.strip
  end
  rex = Sample.new
  tokens = []
  begin
    rex.load_file filename
    while token = rex.next_token
      tokens << token
    end
    return tokens
  rescue
    $stderr.printf "error"
  end
end

def parse                       # MyParser#parse メソッド。(メソッド名は任意)
  begin
    @tokens = to_tokens
    do_parse                      # do_parse でパーサを起動する
  rescue Racc::ParseError => e
    $stderr.puts e, e.backtrace
    $stderr.print 'PARSE ERROR: Near line "',@lineno , '"', "\n"
  end
end

def next_token                  # next_token はパーサ本体から呼び出される
  @info = @tokens.shift
  @lineno = @info[1][:lineno] if @info
  [@info[0], @info[1][:value]] if @info # トークンを返す
end



---- footer ----

if __FILE__ == $0
  parser = MyParser.new         # MyParser インスタンス作成
  Pry::ColorPrinter.pp ast = parser.parse              # MyParser#parse を呼び出す
  #puts ast
  ast.each {|e| e.to_original} if ast
end
