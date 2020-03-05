A DSL for creating DSLs.

Uses cl-event-passing to create pipelines using closures.

Uses tokens (instead of, say, characters).  See token.lisp.

Tokens are 4-tuples: kind, text, line number, position within line (first char is 1).  (There is, also, a 5th house-keeping field - see the discussion of :pulled-p below).

Kind is always a keyword.

In this version, "tokenizer" creates one :character token for each character in the input file.

Token-text for a :character token is a character.

Token-text for a :symbol token is a string.

Token-text for an :integer token is a string (of digits)

Token-text for a :raw token is a string (to end-of-line, excluding the EOL and the first kick-off character (#\$ in this version)).

Token-text for a :ws (whitespace) token is a string containing a single #\Space.  (All other spaces, tabs and newlines are elided).

Token-text for a :comment token is a string containing a single #\Space.  This can be changed by editing comment.lisp.  Comments are to end-of-line (starting with #\% in this version).

Token-text for a :string token is the string including the leading and trailing quotes.  In this version, string begin/end with a double-quote (") and do not handle escape characters (YAGI).  This behaviour can be changed by manipulating the state machine in strings.lisp.

The pipeline is: "tokenize | raw-text | comments | strings | spaces | symbols | integers"  (see parser-schem.lisp).

Filters in the pipeline ignore and forward tokens that don't concern them.

Each filter asks for more tokens by sending a :pull request to the tokenizer.  I don't use temporary files nor Processes (with buffers), just simple queues.

Some filters, like symbols.lisp, buffer characters and emit only a single token containing the buffered text when appropriate.  To make this pipeline work, each token is blessed with a :pulled-p field that tells downstream filters not to emit unneccessary :pull requests for buffered tokens.  (See the various .lisp files to see how that works).

Could I have built this pipeline using functions?  Yes.  But, only because each part has exactly one input and exactly one output (umm, two).

The one-in, one-out paradigm falls apart when scaled up. (It becomes harder to express and to manage and wastes human intellectual power).

==========
syntax - rp uses left-handles to make it easier to parse, each left-handle is exactly one character (which makes it even easier to parse :-)

= <name>            define a rule with given name
- <name>            define a predicate rule with given name, predicate can contain ^ok or ^fail operator
    to perform certain actions (e.g. anything not related to parsing), but we ignore that semantic check for now

[A-Z]+ - (all caps) input a token with the kind given by the symbol (e.g. STRING means input a string), else, error,
    if the token name is followed by "/text", then token must be a symbol and its text must match the given text (text is case sensitive)
'x' character token match - token kind must be :character and text must be a single char with value given (e.g. x)
?'x' - look ahead for a :character token which matches given character, succeed if matched, else fail
?TTT - look ahead for a token with the given kind, succeed if so, else fail
?TTT/text - look ahead for a token with the given kind and text, succeed if so, else fail
* - no-op, always succeeds, only allowed in choice exprs
= - define a new rule whose name is that of the next symbol (e.g. = <architecture> starts a new rule called "<architecture>", N.B. "<" is a valid start-char, and ">" and "-" are valid follow-chars for symbols
[ - start a choice, next item must be a lookahead
| - start another choice clause, next item must be one of...  '<symbol>, :<symbol>, ?<symbol> or *
| * "otherwise"/"else" choice clause, see * above
] - end choice
@symbol - call rule named by the symbol
&symbol - call predicate named by the symbol
symbol - call external routine
^ok or ^fail   return status from predicate
{ begin cycle (forever)
} end cycle
> exit cycle

==========

My naming convention: code is made up of "parts".  Each part is a "state machine" with multiple inputs and multiple outputs.  Each part has one input queue and one output queue.

A message between parts is called an "event".  Events come in two forms - output events and input events.

Input events are 2-tuples {pin-name, data}.  The pin-name is relative to the part accepting the event.

Output events are 2-tuples {pin-name, data}.  The pin-name is relative to the part producing the output event.

Output events are deferred.  When created by SEND(), they are simply enqueued onto the output queue of the the sending event.  When the part has finished processing (one input event), the output queue is released.  Each output event is converted into an input event and pushed onto the input queue of the receiving part.

A part which contains other parts - a composite part -  is called a "schematic" (or schem for short).

A schematic must also contain a routing table, that connects children outputs to children inputs (niggly detail: or self.inputs to children inputs, or self.outputs to chilren outputs, or self.inputs to self.outputs).

If you've touched electronics, then you might see where the above names came from.