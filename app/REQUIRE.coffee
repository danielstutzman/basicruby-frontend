if typeof(window) is 'object'
  window.REQUIRE = {}
  # can't use a loop to DRY this up, because browserify uses static analysis
  #   to determine requirements and needs string literals after require
  window.REQUIRE['app/AstToBytecodeCompiler'] =
    require './AstToBytecodeCompiler'
  window.REQUIRE['app/BytecodeInterpreter'] =
    require './BytecodeInterpreter'
  window.REQUIRE['app/BytecodeSpool'] =
    require './BytecodeSpool'
  window.REQUIRE['app/CasesComponent'] =
    require './CasesComponent'
  window.REQUIRE['app/ConsoleComponent'] =
    require './ConsoleComponent'
  window.REQUIRE['app/DebuggerComponent'] =
    require './DebuggerComponent'
  window.REQUIRE['app/DebuggerController'] =
    require './DebuggerController'
  window.REQUIRE['app/ExerciseComponent'] =
    require './ExerciseComponent'
  window.REQUIRE['app/ExerciseController'] =
    require './ExerciseController'
  window.REQUIRE['app/HeapComponent'] =
    require './HeapComponent'
  window.REQUIRE['app/InstructionsComponent'] =
    require './InstructionsComponent'
  window.REQUIRE['app/Lexer'] =
    require './Lexer'
  window.REQUIRE['app/MenuComponent'] =
    require './MenuComponent'
  window.REQUIRE['app/PartialCallsComponent'] =
    require './PartialCallsComponent'
  window.REQUIRE['app/REQUIRE'] =
    require './REQUIRE'
  window.REQUIRE['app/RubyCodeHighlighter'] =
    require './RubyCodeHighlighter'
  window.REQUIRE['app/ValueComponent'] =
    require './ValueComponent'
  window.REQUIRE['app/VariablesComponent'] =
    require './VariablesComponent'
  window.REQUIRE['app/application'] =
    require './application'
  window.REQUIRE['app/setup_resize_handler'] =
    require './setup_resize_handler'
  window.REQUIRE['app/tutor'] =
    require './tutor'
