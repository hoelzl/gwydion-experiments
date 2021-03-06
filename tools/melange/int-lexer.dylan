documented: #t
module:  int-lexer
author:  Robert Stockton (rgs@cs.cmu.edu)
synopsis: Provides a rough approximation of the lexical conventions of the
          Dylan language, or at least the protions which concern the
          "define interface" form.
copyright: see below
	   This code was produced by the Gwydion Project at Carnegie Mellon
	   University.  If you are interested in using this code, contact
	   "Scott.Fahlman@cs.cmu.edu" (Internet).

//======================================================================
//
// Copyright (c) 1995, 1996, 1997  Carnegie Mellon University
// Copyright (c) 1998, 1999, 2000  Gwydion Dylan Maintainers
// All rights reserved.
// 
// Use and copying of this software and preparation of derivative
// works based on this software are permitted, including commercial
// use, provided that the following conditions are observed:
// 
// 1. This copyright notice must be retained in full on any copies
//    and on appropriate parts of any derivative works.
// 2. Documentation (paper or online) accompanying any system that
//    incorporates this software, or any part of it, must acknowledge
//    the contribution of the Gwydion Project at Carnegie Mellon
//    University, and the Gwydion Dylan Maintainers.
// 
// This software is made available "as is".  Neither the authors nor
// Carnegie Mellon University make any warranty about the software,
// its performance, or its conformity to any specification.
// 
// Bug reports should be sent to <gd-bugs@gwydiondylan.org>; questions,
// comments and suggestions are welcome at <gd-hackers@gwydiondylan.org>.
// Also, see http://www.gwydiondylan.org/ for updates and documentation. 
//
//======================================================================

//======================================================================
//
// Copyright (c) 1994  Carnegie Mellon University
// Copyright (c) 1998, 1999, 2000  Gwydion Dylan Maintainers
// All rights reserved.
//======================================================================

//======================================================================
// Module int-lexer performs lexical analysis for Dylan "define interface"
// clauses.  This will likely disappear when it comes time to merge Melange
// into Gwydion's Dylan compiler.  This file is derived from c-lexer.dylan.
//
// The module exports two major classes -- <tokenizer> and <token> -- along
// with assorted operations, subclasses, and constants.
//
//   <tokenizer>
//      Given some input source, produces a stream of tokens.  Tokenizers 
//      maintain local state.  At present this consists of the current
//      position in the input stream.
//
//   Tokenizers support the following operations:
//     make(<tokenizer>, #key source) -- source may either be a file name or
//       a stream. 
//     get-token(tokenizer) -- returns the next token
//     unget-token(tokenizer, token) -- returns a previously "gotten" token
//       to the beginning of the sequence of available tokens.
//
//    <token>
//      Represents a single input token generated by a tokenizer.
//      Encapsulates: the position in the original source; the character
//      string which generated the token; and the typed "value" of the token.
//      There are numerous subclasses of <token> representing specific
//      reserved words or semantic types (e.g. <semicolon-token> or
//      <string-literal-token>). 
//
//    All tokens support the following operations:
//      value(token) -- returns the abstract "value" of the token.  The
//        type depends upon class of the specific token.
//      string-value(token) -- returns the sequence of characters from which
//        the token's value was derived
//      generator(token) -- returns the tokenizer which generated the
//        token. 
//      parse-error(token, format, args) -- invokes the standard "error" with
//        file and location information prepended to the format string.
//======================================================================

//------------------------------------------------------------------------
// Definitions specific to <tokenizer>s
//------------------------------------------------------------------------

// The public view of tokenizers is described above.  
//
define primary class <tokenizer> (<object>)
  slot file-name :: false-or(<string>),
    init-value: #f, init-keyword: #"source-file";
  slot contents :: <string>, required-init-keyword: #"source-string";
  slot position :: <integer>, init-keyword: #"start", init-value: 0;
  slot unget-stack :: <deque>, init-function: curry(make, <deque>);
end class <tokenizer>;

// Exported operations -- described in module header

define generic get-token
    (tokenizer :: <tokenizer>, #key) => (result :: <token>);
define generic unget-token
    (tokenizer :: <tokenizer>, token :: <token>) => (result :: singleton(#f));

//======================================================================
// Class definitions for and operations upon <token>s
//======================================================================
// Tokens types follow this hierarchy:
//   <token>
//     <simple-token> -- value is the token itself
//       <reserved-word-token>
//         ... -- lots of different tokens, distinguished via the
//                "reserved-words" table.
//       <punctuation-token>
//         ... -- lots of different tokens, distinguished via the
//                "reserved-words" table.
//       <true-eof-token> -- "<eof-token>" is an alias for "<token>", so that
//                           the parser can stip in the middle....
//       <error-token>
//     <name-token> -- value the token string taken as a symbol.
//       <identifier-token>
//     <literal-token>
//        <integer-token> -- value is an integer
//        <string-literal-token> -- value is the token string, minus
//                                  bracketing '"'s and character escapes
//        <character-token> -- value is a single character
//        <keyword-token> -- value is a "symbolic constant"
//        <symbol-literal-token> -- value is a "symbolic constant"
//        <boolean-token> -- value is a boolean
//          <true-token>, <false-token>
//======================================================================

define abstract primary class <token> (<object>)
  constant slot token-id :: <integer> = -1;
  slot string-value :: <string>, required-init-keyword: #"string";
  slot generator, required-init-keyword: #"generator";
  slot position, init-value: #f, init-keyword: #"position";
end;

// This should no longer be necessary -- rgs.
// The parser generator wires in "<eof-token>" as the only permissible
// stopping point.  Since we want to be able to stop in the middle of a file,
// we define it to be identical to "<token>".  If you really want the "end of
// file", use "<true-eof-token>".
//define constant <eof-token> = <token>;

define abstract class <simple-token> (<token>) end class;
define abstract class <reserved-word-token> (<simple-token>) end class;
define abstract class <punctuation-token> (<simple-token>) end class;

define abstract class <name-token> (<token>) end class;

define abstract class <literal-token> (<token>) end class;
define abstract class <boolean-token> (<literal-token>) end class;

#if (~mindy)
define macro token-definer
  { define token ?:name :: ?super:expression = ?value:expression }
    => { define class ?name (?super)
	   inherited slot token-id = ?value;
	 end class ?name;
       }
end macro;

define token <eof-token> :: <simple-token> = 0;
define token <error-token> :: <simple-token> = 1;

define token <integer-token> :: <literal-token> = 2;
define token <character-token> :: <literal-token> = 3;
define token <string-literal-token> :: <literal-token> = 4;
define token <symbol-literal-token> :: <literal-token> = 5;
define token <true-token> :: <boolean-token> = 6;
define token <false-token> :: <boolean-token> = 7;

define token <identifier-token> :: <name-token> = 8;

define token <define-token> :: <reserved-word-token> = 9;
define token <interface-token> :: <reserved-word-token> = 10;
define token <end-token> :: <reserved-word-token> = 11;
define token <include-token> :: <reserved-word-token> = 12;
define token <object-file-token> :: <reserved-word-token> = 13;
define token <mindy-inc-token> :: <reserved-word-token> = 14;
define token <define-macro-token> :: <reserved-word-token> = 15;
define token <undefine-token> :: <reserved-word-token> = 16;
define token <name-mapper-token> :: <reserved-word-token> = 17;
define token <import-token> :: <reserved-word-token> = 18;
define token <prefix-token> :: <reserved-word-token> = 19;
define token <exclude-token> :: <reserved-word-token> = 20;
define token <exclude-file-token> :: <reserved-word-token> = 21;
define token <rename-token> :: <reserved-word-token> = 22;
define token <mapping-token> :: <reserved-word-token> = 23;
define token <equate-token> :: <reserved-word-token> = 24;
define token <superclass-token> :: <reserved-word-token> = 25;
define token <all-token> :: <reserved-word-token> = 26;
define token <none-token> :: <reserved-word-token> = 27;
define token <all-recursive-token> :: <reserved-word-token> = 28;
define token <function-token> :: <reserved-word-token> = 29;
define token <map-result-token> :: <reserved-word-token> = 30;
define token <equate-result-token> :: <reserved-word-token> = 31;
define token <ignore-result-token> :: <reserved-word-token> = 32;
define token <map-argument-token> :: <reserved-word-token> = 33;
define token <equate-argument-token> :: <reserved-word-token> = 34;
define token <input-argument-token> :: <reserved-word-token> = 35;
define token <output-argument-token> :: <reserved-word-token> = 36;
define token <input-output-argument-token> :: <reserved-word-token> = 37;
define token <struct-token> :: <reserved-word-token> = 38;
define token <union-token> :: <reserved-word-token> = 39;
define token <pointer-token> :: <reserved-word-token> = 40;
define token <constant-token> :: <reserved-word-token> = 41;
define token <variable-token> :: <reserved-word-token> = 42;
define token <getter-token> :: <reserved-word-token> = 43;
define token <setter-token> :: <reserved-word-token> = 44;
define token <read-only-token> :: <reserved-word-token> = 45;
define token <seal-token> :: <reserved-word-token> = 46;
define token <seal-functions-token> :: <reserved-word-token> = 47;
define token <sealed-token> :: <reserved-word-token> = 48;
define token <open-token> :: <reserved-word-token> = 49;
define token <inline-token> :: <reserved-word-token> = 50;
define token <value-token> :: <reserved-word-token> = 51;
define token <function-type-token> :: <reserved-word-token> = 52;
define token <callback-maker-token> :: <reserved-word-token> = 53;
define token <callout-function-token> :: <reserved-word-token> = 54;

// A whole bunch of punctuation

define token <semicolon-token> :: <punctuation-token> = 55;
define token <comma-token> :: <punctuation-token> = 56;
define token <lbrace-token> :: <punctuation-token> = 57;
define token <rbrace-token> :: <punctuation-token> = 58;
define token <arrow-token> :: <punctuation-token> = 59;
#else
define class <eof-token> (<simple-token>) 
  inherited slot token-id = 0;
end class;
define class <error-token> (<simple-token>) 
  inherited slot token-id = 1;
end class;

define class <integer-token> (<literal-token>) 
  inherited slot token-id = 2;
end class;
define class <character-token> (<literal-token>) 
  inherited slot token-id = 3;
end class;
define class <string-literal-token> (<literal-token>) 
  inherited slot token-id = 4;
end class;
define class <symbol-literal-token> (<literal-token>) 
  inherited slot token-id = 5;
end class;
define class <true-token> (<boolean-token>) 
  inherited slot token-id = 6;
end class;
define class <false-token> (<boolean-token>) 
  inherited slot token-id = 7;
end class;

define class <identifier-token> (<name-token>) 
  inherited slot token-id = 8;
end class;

define class <define-token> (<reserved-word-token>) 
  inherited slot token-id = 9;
end class;
define class <interface-token> (<reserved-word-token>) 
  inherited slot token-id = 10;
end class;
define class <end-token> (<reserved-word-token>) 
  inherited slot token-id = 11;
end class;
define class <include-token> (<reserved-word-token>) 
  inherited slot token-id = 12;
end class;
define class <object-file-token> (<reserved-word-token>) 
  inherited slot token-id = 13;
end class;
define class <mindy-inc-token> (<reserved-word-token>) 
  inherited slot token-id = 14;
end class;
define class <define-macro-token> (<reserved-word-token>) 
  inherited slot token-id = 15;
end class;
define class <undefine-token> (<reserved-word-token>) 
  inherited slot token-id = 16;
end class;
define class <name-mapper-token> (<reserved-word-token>) 
  inherited slot token-id = 17;
end class;
define class <import-token> (<reserved-word-token>) 
  inherited slot token-id = 18;
end class;
define class <prefix-token> (<reserved-word-token>) 
  inherited slot token-id = 19;
end class;
define class <exclude-token> (<reserved-word-token>) 
  inherited slot token-id = 20;
end class;
define class <exclude-file-token> (<reserved-word-token>) 
  inherited slot token-id = 21;
end class;
define class <rename-token> (<reserved-word-token>) 
  inherited slot token-id = 22;
end class;
define class <mapping-token> (<reserved-word-token>) 
  inherited slot token-id = 23;
end class;
define class <equate-token> (<reserved-word-token>) 
  inherited slot token-id = 24;
end class;
define class <superclass-token> (<reserved-word-token>) 
  inherited slot token-id = 25;
end class;
define class <all-token> (<reserved-word-token>) 
  inherited slot token-id = 26;
end class;
define class <none-token> (<reserved-word-token>) 
  inherited slot token-id = 27;
end class;
define class <all-recursive-token> (<reserved-word-token>) 
  inherited slot token-id = 28;
end class;
define class <function-token> (<reserved-word-token>) 
  inherited slot token-id = 29;
end class;
define class <map-result-token> (<reserved-word-token>) 
  inherited slot token-id = 30;
end class;
define class <equate-result-token> (<reserved-word-token>) 
  inherited slot token-id = 31;
end class;
define class <ignore-result-token> (<reserved-word-token>) 
  inherited slot token-id = 32;
end class;
define class <map-argument-token> (<reserved-word-token>) 
  inherited slot token-id = 33;
end class;
define class <equate-argument-token> (<reserved-word-token>) 
  inherited slot token-id = 34;
end class;
define class <input-argument-token> (<reserved-word-token>) 
  inherited slot token-id = 35;
end class;
define class <output-argument-token> (<reserved-word-token>) 
  inherited slot token-id = 36;
end class;
define class <input-output-argument-token> (<reserved-word-token>) 
  inherited slot token-id = 37;
end class;
define class <struct-token> (<reserved-word-token>) 
  inherited slot token-id = 38;
end class;
define class <union-token> (<reserved-word-token>) 
  inherited slot token-id = 39;
end class;
define class <pointer-token> (<reserved-word-token>) 
  inherited slot token-id = 40;
end class;
define class <constant-token> (<reserved-word-token>) 
  inherited slot token-id = 41;
end class;
define class <variable-token> (<reserved-word-token>) 
  inherited slot token-id = 42;
end class;
define class <getter-token> (<reserved-word-token>) 
  inherited slot token-id = 43;
end class;
define class <setter-token> (<reserved-word-token>) 
  inherited slot token-id = 44;
end class;
define class <read-only-token> (<reserved-word-token>) 
  inherited slot token-id = 45;
end class;
define class <seal-token> (<reserved-word-token>) 
  inherited slot token-id = 46;
end class;
define class <seal-functions-token> (<reserved-word-token>) 
  inherited slot token-id = 47;
end class;
define class <sealed-token> (<reserved-word-token>) 
  inherited slot token-id = 48;
end class;
define class <open-token> (<reserved-word-token>) 
  inherited slot token-id = 49;
end class;
define class <inline-token> (<reserved-word-token>) 
  inherited slot token-id = 50;
end class;
define class <value-token> (<reserved-word-token>) 
  inherited slot token-id = 51;
end class;
define class <function-type-token> (<reserved-word-token>) 
  inherited slot token-id = 52;
end class;
define class <callback-maker-token> (<reserved-word-token>) 
  inherited slot token-id = 53;
end class;
define class <callout-function-token> (<reserved-word-token>) 
  inherited slot token-id = 54;
end class;

// A whole bunch of punctuation

define class <semicolon-token> (<punctuation-token>) 
  inherited slot token-id = 55;
end class;
define class <comma-token> (<punctuation-token>) 
  inherited slot token-id = 56;
end class;
define class <lbrace-token> (<punctuation-token>) 
  inherited slot token-id = 57;
end class;
define class <rbrace-token> (<punctuation-token>) 
  inherited slot token-id = 58;
end class;
define class <arrow-token> (<punctuation-token>) 
  inherited slot token-id = 59;
end class;
#endif

define sealed generic string-value (token :: <token>) => (result :: <string>);
define sealed generic value (token :: <token>) => (result :: <object>);
define sealed generic parse-error
    (token :: <token>, format :: <string>, #rest args)
 => ();				// never returns

// Literal tokens (and those not otherwise modified) evaluate to themselves.
//
define method value (token :: <token>) => (result :: <token>);
  token;
end method value;

// Name values are interned as symbols so that they will be case insensitive.
//
define method value (token :: <name-token>) => (result :: <symbol>);
  as(<symbol>, token.string-value);
end method value;

define class <keyword-token> (<token>) end class;

// Keyword values are interned as symbols (without the terminating colon) so
// that they will be case insensitive.
//
define method value (token :: <keyword-token>) => (result :: <symbol>);
  as(<symbol>, copy-sequence(token.string-value,
			     end: token.string-value.size - 1))
end method value;

// Boolean tokens may be #t or #f.  Figure out which.
//
define method value (token :: <boolean-token>) => (result :: <boolean>);
  ~instance?(token, <false-token>);
end method value;

// Symbol literals are interned as symbols after the various quotation stuff
// is stripped off.
//
define method value
    (token :: <symbol-literal-token>) => (result :: <symbol>);
  as(<symbol>, copy-sequence(token.string-value,
			     start: 2, end: token.string-value.size - 1))
end method value;

// Integer tokens can be in one of three different radices.  Figure out which
// and then compute an integer value.
//
define method value (token :: <integer-token>) => (result :: <integer>);
  let string = token.string-value;
  case
    string.first ~= '#' =>
      string-to-integer(string);
    string.second == 'o' | string.second == 'O' =>
      string-to-integer(copy-sequence(string, start: 2), base: 8);
    otherwise =>
      string-to-integer(copy-sequence(string, start: 2), base: 16);
  end case;
end method value;

// non-alphanumeric characters.  This routine translates the second character
// of such a sequence into the appropriate "escaped character".
//
define method escaped-character (char :: <character>) => (esc :: <character>);
  select (char)
    'a' => as(<character>, 7);
    'b' => as(<character>, 8);
    't' => as(<character>, 9);
    'n' => as(<character>, 10);
    'v' => as(<character>, 11);
    'f' => as(<character>, 12);
    'r' => as(<character>, 13);
    otherwise => char;
  end select;
end method escaped-character;

// Character tokens evaluate to characters.  We must handle two character
// "escape sequences" as well as simple literals.
//
define method value (token :: <character-token>) => (result :: <character>);
  let string = token.string-value;
  if (string[1] == '\\')
    escaped-character(string[2]);
  else
    string[1];
  end if;
end method value;
  
// String literals evaluate to strings (without the bracketing quotation
// marks).  Handling is complicated by the possibility that there will be
// "character escape"s in the string.
//
define method value (token :: <string-literal-token>) => (result :: <string>);
  let string = token.string-value;
  let new = make(<stretchy-vector>);

  local method process-char (position :: <integer>) => ();
	  let char = string[position];
	  if (char == '\\')
	    add!(new, escaped-character(string[position + 1]));
	    process-char(position + 2);
	  elseif (char ~= '"')
	    add!(new, char);
	    process-char(position + 1);
          // else we're done, so fall through
	  end if;
	end method process-char;
  process-char(1);
  as(<string>, new);
end method value;


// When we have a specific token that triggered an error, this routine can
// used saved character positions to precisely identify the location.
//
define method parse-error (token :: <token>, format :: <string>, #rest args)
 => ();	// never returns
  let source-string = token.generator.contents;
  let line-num = 1;
  let last-CR = -1;

  for (i from 0 below token.position | 0)
    if (source-string[i] == '\n')
      line-num := line-num + 1;
      last-CR := i;
    end if;
  end for;

  let char-num = (token.position | 0) - last-CR;
  apply(error, concatenate("%s:line %d: ", format),
	token.generator.file-name | "<unknown-file>", line-num, args);
end method parse-error;

//========================================================================
// "Simple" operations on tokenizers
//========================================================================

// Stores a previously analyzed token for later return
//
define method unget-token (state :: <tokenizer>, token :: <token>)
  => (result :: singleton(#f));
  push(state.unget-stack, token);
  #f;
end method unget-token;

//======================================================================
// A bunch of specialized routines which together support "get-token"
//======================================================================

// Internal error messages generated by the lexer.  We have to go through some
// messy stuff to get to the "current" file name.
// 
define method lex-error (generator :: <tokenizer>, format :: <string>,
			 #rest args)
 => ();	// never returns
  apply(error, concatenate("%s:char %d: ", format),
	"<unknown-file>", generator.position | -1, args);
end method lex-error;

// Each pair of elements in this vector specifies a literal constant
// corresponding to a C reserved word and the token class it belongs to.
define constant reserved-words
  = vector("define", <define-token>,
	   "interface", <interface-token>,
	   "end", <end-token>,
	   "#include", <include-token>,
	   "object-file:", <object-file-token>,
	   "mindy-include-file:", <mindy-inc-token>,
	   "define:", <define-macro-token>,
	   "undefine:", <undefine-token>,
	   "name-mapper:", <name-mapper-token>,
	   "import:", <import-token>,
	   "prefix:", <prefix-token>,
	   "exclude:", <exclude-token>,
	   "exclude-file:", <exclude-file-token>,
	   "rename:", <rename-token>,
	   "map:", <mapping-token>,
	   "equate:", <equate-token>,
	   "superclasses:", <superclass-token>,
	   "all", <all-token>,
	   "none", <none-token>,
	   "all-recursive", <all-recursive-token>,
           "function", <function-token>,
           "map-result:", <map-result-token>,
           "equate-result:", <equate-result-token>,
           "ignore-result:", <ignore-result-token>,
           "map-argument:", <map-argument-token>,
           "equate-argument:", <equate-argument-token>,
           "input-argument:", <input-argument-token>,
           "output-argument:", <output-argument-token>,
           "input-output-argument:", <input-output-argument-token>,
	   "struct", <struct-token>,
	   "union", <union-token>,
	   "pointer", <pointer-token>,
//          Again, no clue what this is supposed to be.
//	   "constant", <constant-token>,
	   "variable", <variable-token>,
	   "getter:", <getter-token>,
	   "setter:", <setter-token>,
	   "read-only:", <read-only-token>,
	   "seal:", <seal-token>,
	   "seal-functions:", <seal-functions-token>,
	   "sealed", <sealed-token>,
	   "open", <open-token>,
	   "inline", <inline-token>,
	   "value:", <value-token>,
	   "function-type", <function-type-token>,
	   "callback-maker:", <callback-maker-token>,
	   "callout-function:", <callout-function-token>,
	   "#t", <true-token>,
	   "#f", <false-token>,
	   ",", <comma-token>,
	   ";", <semicolon-token>,
	   "{", <lbrace-token>,
	   "}", <rbrace-token>,
	   "=>", <arrow-token>);

// This table maps reserved words (as "symbol" literals) to the corresponding
// token class.  It is initialized from the "reserved-words" vector defined
// above
//
define constant reserved-word-table =
  make(<object-table>, size: truncate/(reserved-words.size, 2));

// Do the actual initialization of reserved-word-table at load time.
//
for (index from 0 below reserved-words.size by 2)
  reserved-word-table[as(<symbol>, reserved-words[index])]
    := reserved-words[index + 1]; 
end for;

// Looks for special classes of tokens and acts appropriately.  This includes
// reserved words, keywods, symbolic literals, and punctuation.  These are
// identified by entries in reserved-word-table.
//
define method lex-identifier
    (tokenizer :: <tokenizer>, position :: <integer>, string :: <string>)
 => (token :: <token>);
  let symbol = as(<symbol>, string);
  if (string.first == '#')
    let token-class = element(reserved-word-table, symbol, default: #f);
    if (string.last == ':' | token-class == #f)
      lex-error(tokenizer, "Bad keyword.");
    end if;
    make(token-class, position: position, string: string,
	 generator: tokenizer);
  else
    let default
      = if (string.last == ':') <keyword-token> else <identifier-token> end;
    let token-class = element(reserved-word-table, symbol, default: default);
    make(token-class, position: position, string: string,
	 generator: tokenizer);
  end if;
end method lex-identifier;

// This is complicated by the need to insure that we *don't* match octal and
// hexedecimal integer literals.
//
define constant match-ID
  = make-regexp-positioner("^(#[^xXoO]|[!&*<=>|^$%@_a-zA-Z])("
			     "[-!&*<=>|^$%@_+~?/a-zA-Z0-9]*"
			     "|[0-9][-!&*<=>|^$%@_+~?/a-zA-Z0-9]*"
			     "[a-zA-Z][a-zA=Z]"
			     "[-!&*<=>|^$%@_+~?/a-zA-Z0-9]*):?");

// Attempts to match "words" (i.e. identifiers or reserved words) or
// keywords.  Returns a token if the match is succesful and #f otherwise.
//
define method try-identifier
    (state :: <tokenizer>, position :: <integer>)
 => (result :: false-or(<token>));
  let contents :: <string> = state.contents;

  let (start-index, end-index)
    = match-ID(contents, start: position);
  if (start-index == #f)
    #f;
  else
    state.position := end-index;
    let string-value = copy-sequence(contents,
				     start: position, end: end-index);
    lex-identifier(state, position, string-value);
  end if;
end method try-identifier;

define constant match-punctuation
  = make-regexp-positioner("^(=>|[,;{}])", byte-characters-only: #t);

// Attempts to match "punctuation".  Returns a token if the match is succesful
// and #f otherwise.
//
define method try-punctuation (state :: <tokenizer>, position :: <integer>)
 => result :: false-or(<token>);
  let contents :: <string> = state.contents;

  if (punctuation?(contents[position]))
    let (start-index, end-index)
      = match-punctuation(contents, start: position);
    if (start-index ~= #f)
      state.position := end-index;
      let string-value = copy-sequence(contents,
				       start: position, end: end-index);
      lex-identifier(state, position, string-value);
    end if;
  end if;
end method try-punctuation;

define method is-prefix?
    (short :: <string>, long :: <string>, #key start = 0)
 => (result :: <boolean>);
  if (size(short) > size(long) - start)
    #f;
  else
    block (return)
      for (short-char in short,
	   index from start)
	if (short-char ~= long[index]) return(#f) end if;
      end for;
      #t;
    end block;
  end if;
end method is-prefix?;

define constant match-comment-component
  = make-regexp-positioner("\\*/|(/\\*|//)",
			   byte-characters-only: #t);

// Skip over whitespace characters (including newlines) and comments.
//
define method skip-whitespace (contents :: <string>, position :: <integer>)
 => (position :: <integer>);
  let sz = contents.size;

  local
    method find-comment-end (index :: <integer>) => (end-index :: <integer>);
      let (first, last, nested?) =
	match-comment-component(contents, start: index);
      if (nested?)
	find-comment-end(skip-comment(first));
      else
	last;
      end if;
    end method find-comment-end,
    method skip-comment (index :: <integer>) => (end-index :: <integer>);
      // The string literal looks odd, but things that look like comments
      // can really confuse the emacs mode....
      if (is-prefix?("/" "/", contents, start: index))
	for (j from index + 2 below sz,
	     until: contents[j] == '\n')
	finally
	  j
	end for;
      elseif (is-prefix?("/*", contents, start: index))
	find-comment-end(index + 2);
      else
	index;
      end if;
    end method skip-comment;
  for (i from position below sz,
       until: (~whitespace?(contents[i])))
  finally
    let comment-end = skip-comment(i);
    if (comment-end == i)
      // no comment -- we're done
      i;
    else
      skip-whitespace(contents, comment-end);
    end if;
  end for;
end method skip-whitespace;

// This matcher is used to match various literals.  Marks will be generated as
// follows:
//   [0, 1] and [2, 3] -- start and end of the entire match
//   [3, 4] -- start and end of character literal contents
//   [5, 6] -- start and end of string literal contents
//   [7, 8] -- start and end of integer literal
//
define constant match-literal
  = make-regexp-positioner("^('(\\\\?.)'|"
			     "(#?\"([^\"]|\\\\\")*\")|"
			     "(([1-9][0-9]*)|(#[xX][0-9a-fA-F]+)|(#[oO][0-7]*)))",
			   byte-characters-only: #t);

// Returns a <token> object and updates state to reflect the token's
// consumption. 
//
define method get-token
    (state :: <tokenizer>, #key position: init-position)
 => (token :: <token>);
  block (return)
    let pos = init-position | state.position;

    // If we have old tokens, just pop them from the stack and return them
    if (~state.unget-stack.empty?)
      return(pop(state.unget-stack));
    end if;

    let contents = state.contents;
    local method string-value(start-index, end-index)
	    copy-sequence(contents, start: start-index, end: end-index);
	  end method string-value;

    // Get rid of whitespace, whether it be spaces, newlines, or comments
    let pos = skip-whitespace(contents, pos);
    if (pos = contents.size)
      state.position := pos;
      return(make(<eof-token>, position: pos, generator: state,
		  string: ""));
    end if;

    // Do the appropriate matching, and return an <error-token> if we don't
    // find a match.
    let token? =
      try-identifier(state, pos) | try-punctuation(state, pos);
    if (token?) return(token?) end if;

    let (start-index, end-index, dummy1, dummy2, char-start, char-end,
	 string-start, string-end, string-contents-start, string-contents-end,
	 int-start, int-end)
      = match-literal(contents, start: pos);

    if (start-index)
      // At most one of the specialized start indices will be non-false.  Look
      // for that one and build the appropriate token.
      state.position := end-index;
      let token-type = case
			 char-start =>
			   <character-token>;
			 string-start & contents[string-start] == '#' =>
			   <symbol-literal-token>;
			 string-start =>
			   <string-literal-token>;
			 int-start =>
			   <integer-token>;
		       end case;
      return(make(token-type, position: pos,
		  string: string-value(pos, end-index), generator: state));
    end if;

    // None of our searches matched, so we haven't the foggiest what this is.
    lex-error(state, "Major botch in get-token.");
  end block;
end method get-token;

// Seals for file int-lexer.dylan

// <tokenizer> -- subclass of <object>
define sealed domain make(singleton(<tokenizer>));
define sealed domain initialize(<tokenizer>);
// <eof-token> -- subclass of <simple-token>
define sealed domain make(singleton(<eof-token>));
// <error-token> -- subclass of <simple-token>
define sealed domain make(singleton(<error-token>));
// <identifier-token> -- subclass of <name-token>
define sealed domain make(singleton(<identifier-token>));
// <keyword-token> -- subclass of <token>
define sealed domain make(singleton(<keyword-token>));
// <integer-token> -- subclass of <literal-token>
define sealed domain make(singleton(<integer-token>));
// <character-token> -- subclass of <literal-token>
define sealed domain make(singleton(<character-token>));
// <string-literal-token> -- subclass of <literal-token>
define sealed domain make(singleton(<string-literal-token>));
// <symbol-literal-token> -- subclass of <literal-token>
define sealed domain make(singleton(<symbol-literal-token>));
// <true-token> -- subclass of <boolean-token>
define sealed domain make(singleton(<true-token>));
// <false-token> -- subclass of <boolean-token>
define sealed domain make(singleton(<false-token>));
// <define-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<define-token>));
// <interface-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<interface-token>));
// <end-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<end-token>));
// <include-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<include-token>));
// <object-file-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<object-file-token>));
// <mindy-inc-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<mindy-inc-token>));
// <define-macro-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<define-macro-token>));
// <undefine-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<undefine-token>));
// <name-mapper-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<name-mapper-token>));
// <import-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<import-token>));
// <prefix-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<prefix-token>));
// <exclude-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<exclude-token>));
// <exclude-file-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<exclude-file-token>));
// <rename-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<rename-token>));
// <mapping-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<mapping-token>));
// <equate-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<equate-token>));
// <superclass-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<superclass-token>));
// <all-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<all-token>));
// <none-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<none-token>));
// <all-recursive-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<all-recursive-token>));
// <function-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<function-token>));
// <map-result-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<map-result-token>));
// <equate-result-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<equate-result-token>));
// <ignore-result-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<ignore-result-token>));
// <map-argument-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<map-argument-token>));
// <equate-argument-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<equate-argument-token>));
// <input-argument-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<input-argument-token>));
// <output-argument-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<output-argument-token>));
// <input-output-argument-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<input-output-argument-token>));
// <struct-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<struct-token>));
// <union-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<union-token>));
// <pointer-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<pointer-token>));
// <constant-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<constant-token>));
// <variable-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<variable-token>));
// <getter-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<getter-token>));
// <setter-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<setter-token>));
// <read-only-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<read-only-token>));
// <seal-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<seal-token>));
// <seal-functions-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<seal-functions-token>));
// <sealed-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<sealed-token>));
// <open-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<open-token>));
// <inline-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<inline-token>));
// <value-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<value-token>));
// <function-type-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<function-type-token>));
// <callback-maker-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<callback-maker-token>));
// <callout-function-token> -- subclass of <reserved-word-token>
define sealed domain make(singleton(<callout-function-token>));
// <semicolon-token> -- subclass of <punctuation-token>
define sealed domain make(singleton(<semicolon-token>));
// <comma-token> -- subclass of <punctuation-token>
define sealed domain make(singleton(<comma-token>));
// <lbrace-token> -- subclass of <punctuation-token>
define sealed domain make(singleton(<lbrace-token>));
// <rbrace-token> -- subclass of <punctuation-token>
define sealed domain make(singleton(<rbrace-token>));
// <arrow-token> -- subclass of <punctuation-token>
define sealed domain make(singleton(<arrow-token>));
