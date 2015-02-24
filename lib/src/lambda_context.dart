part of mustache;

/// Passed as an argument to a mustache lambda function.
class _LambdaContext implements LambdaContext {
  
  final _Node _node;
  final _RenderContext _context;
  final bool _isSection;
  bool _closed = false;
  
  _LambdaContext(this._node, this._context, {bool isSection: true})
      : _isSection = isSection;
  
  void close() {
    _closed = true;
  }
  
  void _checkClosed() {
    if (_closed) throw _error('LambdaContext accessed outside of callback.');
  }
  
  _TemplateException _error(String msg) {
    return new _TemplateException(msg, _context.templateName, _context.source,
        _node.start);    
  }
  
  /// Render the current section tag in the current context and return the
  /// result as a string.
  String renderString() {
    if (_node is! _SectionNode) _error(
        'LambdaContext.renderString() can only be called on section tags.');
    _checkClosed();
    var sink = new StringBuffer();
    var ctx = new _RenderContext.subtree(_context, sink);
    _SectionNode section = _node;
    _renderWithContext(ctx, section.children);
    return sink.toString();
  }

  //FIXME Currently only return values are supported.
  /// Render and directly output the current section tag.
//  void render() {
//    _checkClosed();
//  }

  //FIXME Currently only return values are supported.
  /// Output a string.
//  void write(Object object) {
//    _checkClosed();
//  }

  /// Get the unevaluated template source for the current section tag.
  String get source {
    _checkClosed();
    
    if (_node is! _SectionNode) return '';
    
    var nodes = (_node as _SectionNode).children;
    
    if (nodes.isEmpty) return '';
    
    if (nodes.length == 1 && nodes.first is _TextNode)
      return nodes.first.text;
    
    var source = _context.source.substring(
        _node.contentStart, _node.contentEnd);
    
    return source;
  }

  /// Evaluate the string as a mustache template using the current context.
  String renderSource(String source) {
    _checkClosed();
    var sink = new StringBuffer();
    
    // Lambdas used for sections should parse with the current delimiters.
    var delimiters = '{{ }}';
    if (_node is _SectionNode) {
      _SectionNode node = _node;
      delimiters = node.delimiters;
    }
    
    var nodes = _parse(source,
        _context.lenient,
        _context.templateName,
        delimiters);
    
    var ctx = new _RenderContext.lambda(
        _context,
        source,
        _context.indent,
        sink,
        delimiters);
    
    _renderWithContext(ctx, nodes);

    return sink.toString();
  }

  /// Lookup the value of a variable in the current context.
  Object lookup(String variableName) {
    _checkClosed();
    return _context.resolveValue(variableName);
  }

}