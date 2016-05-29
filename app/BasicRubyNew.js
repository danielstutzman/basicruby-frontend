require('opal'); // sets Opal global

(function() {

gotCallbackGlobal = null;

function parseToSexp(rubySource) {
  var $scope = Opal;
  Opal.add_stubs(['$new', '$compile', '$instance_variable_get']);
  compiler = (($scope.get('Opal')).$$scope.get('Compiler')).$new(rubySource);
  compiler.$compile();
  return compiler.$instance_variable_get("@sexp");
}

function continueRecursion(f, s) {
  var name   = s.array[0];
  if (name == 'top' || name == 'js_return') {
    f(s.array[1]);
  } else if (name == 'block' || name == 'arglist') {
    for (var i = 1; i < s.array.length; i++) {
      f(s.array[i]);
    }
  } else if (name == 'call') {
    if (s.array[1].array) {
      f(s.array[1]);
    }
    if (s.array[3].array) {
      f(s.array[3]);
    }
  } else if (name == 'int' || name == 'str' || name == 'lvar') {
    // no further recursion is possible
  } else if (name == 'def') {
    if (s.array[1].$$id != 4) {
      throw new Error('Expected nil in def.array[1]');
    }
    if (s.array[4].array[0] != 'block') {
      throw new Error('Expected block in def.array[4]');
    }
    f(s.array[4]);
  } else if (name == 'return') {
    f(s.array[1]);
  } else if (name == 'lasgn') {
    f(s.array[2]);
  } else if (name == 'paren') {
    f(s.array[1]);
  } else {
    throw new Error("Don't know how to handle sexp of type '" + name + "'");
  }
}

function convertRowColToOffsets(s, lineNumToOffset) {
  //console.log('convertRowColToOffsets', s);
  continueRecursion(function(s) { convertRowColToOffsets(s, lineNumToOffset) }, s);
  if (s.source && s.source.length) {
    var source = s.source;
    if (lineNumToOffset[source[0]] === undefined) {
      throw new Error("Couldn't find lineNumToOffset[" + source[0] + "]");
    }
    if (lineNumToOffset[source[2]] === undefined) {
      throw new Error("Couldn't find lineNumToOffset[" + source[2] + "]");
    }
    source.push(lineNumToOffset[source[0]] + source[1]);
    source.push(lineNumToOffset[source[2]] + source[3]);
  }
}

function instrumentRuby(s, offsetToAdditions, rubySource) {
  //console.log('instrumentRuby', s);
  continueRecursion(function(s) {
    instrumentRuby(s, offsetToAdditions, rubySource)
  }, s);
  if (s.source && s.source.length) {
    //console.log('Handling source', s.source);

    var methodReceiverId  = null;
    var methodName        = null;
    var methodArgumentIds = null;
    if (s.array[0] == 'call') {
      methodReceiverId = s.array[1].$$id;
      methodName       = s.array[2];
      methodArgumentIds = [];
      arglist = s.array[3].array;
      //console.log('arglist', arglist);
      for (var i = 1; i < arglist.length; i++) {
        methodArgumentIds.push(arglist[i].$$id);
      }
      //console.log('methodArgids', methodArgumentIds);
    } else if (s.array[0] == 'def') {
      methodName = s.array[2];
    } else if (s.array[0] == 'lvar') {
      methodName = s.array[1];
    } else if (s.array[0] == 'lasgn') {
      methodName = s.array[1];
    }

    // For method calls we want to call 'got' with 'start_method' just before
    // the method evaluation starts.  The only way is to surround the last
    // argument: e.g. f(1,2,3) changes to f(1,2,start_method(3))
    // If there's no last argument, send in *start_method([])
    if (s.array[0] == 'call') {
      var arglist = s.array[3];
      var numArgs = arglist.array.length - 1;
      var offsetStart;
      var needsExtraParens;
      //console.log('numArgs', numArgs);
      if (numArgs > 0) {
        var lastArg = arglist.array[numArgs];
        offsetStart = lastArg.source[4];
        needsExtraParens = false;
      } else {
        //console.log('source is', rubySource.charAt(s.source[5] - 1));
        //console.log('char is', rubySource.charAt(s.source[5] - 1));
        needsExtraParens = (rubySource.charAt(s.source[5] - 1) != ')');
        if (needsExtraParens) {
          offsetStart = s.source[5];
        } else {
          offsetStart = s.source[5] - 1; // before the closing paren
        }
      }

      if (offsetToAdditions[offsetStart] === undefined) {
        offsetToAdditions[offsetStart] = [];
      }
      offsetToAdditions[offsetStart].unshift(
        (numArgs == 0 ? (needsExtraParens ? '(*(' : '*(') : '') +
        "got('start_call'," +
        s.source[0] + ',' + s.source[1] + ',' +
        s.source[2] + ',' + s.source[3] + "," +
        (methodReceiverId || 'nil') + "," +
        "'" + (methodName || 'nil') + "'," +
        (methodArgumentIds ? methodArgumentIds.$inspect() : 'nil') + "," +
        s.$$id + ",(" +
        (numArgs == 0 ? (needsExtraParens ? '[]))' : '[])') : '')
        );

      var offsetEnd;
      if (numArgs > 0) {
        offsetEnd = lastArg.source[5];
      } else {
        if (needsExtraParens) {
          offsetEnd = s.source[5];
        } else {
          offsetEnd = s.source[5] - 1; // before the closing paren
        }
      }
      if (offsetToAdditions[offsetEnd] === undefined) {
        offsetToAdditions[offsetEnd] = [];
      }
      // push not unshift because recursion will go to children first
      offsetToAdditions[offsetEnd].push("))");
    }

    var offsetStart = s.source[4];
    if (offsetToAdditions[offsetStart] === undefined) {
      offsetToAdditions[offsetStart] = [];
    }
    // unshift not push because recursion will go to children first
    offsetToAdditions[offsetStart].unshift("got('" + s.array[0] + "'," +
        s.source[0] + ',' + s.source[1] + ',' +
        s.source[2] + ',' + s.source[3] + "," +
        (methodReceiverId || 'nil') + "," +
        "'" + (methodName || 'nil') + "'," +
        (methodArgumentIds ? methodArgumentIds.$inspect() : 'nil') + "," +
        s.$$id + ",(");

    if (s.array[0] == 'def') {
      offsetToAdditions[offsetStart].unshift(
        "remember_to_undefine('" + methodName + "');")
    }

    var offsetEnd = s.source[5];
    if (offsetToAdditions[offsetEnd] === undefined) {
      offsetToAdditions[offsetEnd] = [];
    }
    // push not unshift because recursion will go to children first
    offsetToAdditions[offsetEnd].push("))");
  }
}

function runRubyWithHighlighting(rubySource, gotCallback) {
  gotCallbackGlobal = gotCallback;

  var lineNumToOffset = {};
  var rubySourceLines = rubySource.split("\n");
  var offsetSoFar = 0;
  for (var lineNum0 = 0; lineNum0 < rubySourceLines.length; lineNum0++) {
    lineNumToOffset[lineNum0 + 1] = offsetSoFar; // + 1 since line nums start at 1
    offsetSoFar += rubySourceLines[lineNum0].length + 1; // + 1 for the newline
  }

  var sexp = parseToSexp(rubySource);
  console.log(JSON.stringify(sexp, null, 2));
  convertRowColToOffsets(sexp, lineNumToOffset);
  //console.log('sexp', sexp);
  //console.log(JSON.stringify(sexp, null, 2));

  var offsetToAdditions = {};
  instrumentRuby(sexp, offsetToAdditions, rubySource);
  //console.log(offsetToAdditions);
  var offsets = Object.keys(offsetToAdditions).sort(function(a,b) { return a - b; });
  //console.log('offsets', offsets);
  var lastOffset = 0;
  var instrumentedSource = [];
  for (var offset in offsetToAdditions) {
    instrumentedSource.push(rubySource.substring(lastOffset, offset));
    instrumentedSource = instrumentedSource.concat(offsetToAdditions[offset]);
    lastOffset = offset;
  }
  instrumentedSource.push(rubySource.substring(lastOffset));
  console.log('instrumented:', instrumentedSource);

  prelude = "def got(name, row0, col0, row1, col1, method_receiver, method_name, method_argument_ids, save_as_id, expr)\n" +
    "  console_texts = $console_texts\n" +
    "  `gotCallbackGlobal(name, row0, col0, row1, col1, method_receiver, method_name, method_argument_ids, save_as_id, expr, console_texts)`\n" +
    "  expr\n" +
    "end\n" +

    "def remember_to_undefine(name)\n" +
    "  $methods_to_restore = {} if $methods_to_restore.nil?\n" +
    "  unless $methods_to_restore.has_key? name\n" +
    "    begin\n" +
    "      $methods_to_restore[name] = receiver.method(name)\n" +
    "    rescue NameError\n" +
    "      $methods_to_restore[name] = nil\n" +
    "    end\n" +
    "  end\n" +
    "end\n" +

    "# redefine puts to handle trailing newlines like MRI does\n" +
    "def puts *args\n" +
    "  if args.size > 0\n" +
    "    $stdout.write args.map { |arg|\n" +
    "      arg_to_s = \"#{arg}\"\n" +
    "      arg_to_s + (arg_to_s.end_with?(\"\n\") ? \"\" : \"\n\")\n" +
    "    }.join\n" +
    "  else\n" +
    "    $stdout.write \"\n\"\n" +
    "  end\n" +
    "  nil\n" +
    "end\n" +

    "def p *args\n" +
    "  args.each do |arg|\n" +
    "    $stdout.write arg.inspect + \"\n\"\n" +
    "  end\n" +
    "  case args.size\n" +
    "    when 0 then nil\n" +
    "    when 1 then args[0]\n" +
    "    else args\n" +
    "  end\n" +
    "end\n" +

    "$console_texts = []\n" +
    "$is_capturing_output = true\n" +
    "class <<$stdout\n" +
    "  alias :old_write :write\n" +
    "  def write *args\n" +
    "    if $is_capturing_output\n" +
    "      $console_texts = $console_texts.clone +\n" +
    "        args.map { |arg| [:stdout, \"#{arg}\"] }\n" +
    "    else\n" +
    "      old_write *args\n" +
    "    end\n" +
    "  end\n" +
    "end\n" +
    "class <<$stderr\n" +
    "  alias :old_write :write\n" +
    "  def write *args\n" +
    "    if $is_capturing_output\n" +
    "      $console_texts = $console_texts.clone +\n" +
    "        args.map { |arg| [:stderr, \"#{arg}\"] }\n" +
    "    else\n" +
    "      old_write *args\n" +
    "    end\n" +
    "  end\n" +
    "end\n"
  instrumentedSource = prelude + instrumentedSource.join('');

  Opal.eval(instrumentedSource);

  // undefine methods or redefine them
  var methods_to_restore = Opal.gvars.methods_to_restore;
  if (methods_to_restore !== undefined) {
    for (var i = 0; i < methods_to_restore.$$keys.length; i++) {
      var methodName = methods_to_restore.$$keys[i];
      var existingDef = methods_to_restore.$$map[methodName];
      if (existingDef) {
        Opal.Object.$send("define_method", methodName, existingDef);
      } else {
        Opal.Object.$send("remove_method", methodName);
      }
    }
    delete Opal.gvars.methods_to_restore;
  }
}

module.exports = {
  runRubyWithHighlighting: runRubyWithHighlighting
};

//var rubySource = "def f(x)\n x + 1\n end\n p f(2)"
//var rubySource = "p 1 + 2 + 3";
})();
