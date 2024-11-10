import 'dart:io';
import 'dart:convert';

class TreeNode {
  String path;
  String word;
  String translation;
  Map<String, TreeNode> children = {};

  TreeNode(this.path, this.word, this.translation);

  Map<String, dynamic> toJson() => {
        'path': path,
        'word': word,
        'translation': translation,
        'children': children.keys.toList(),
      };
}

class CSVTreeEditor {
  final String filePath;
  final Map<String, TreeNode> root = {};

  CSVTreeEditor(this.filePath);

  void load() {
    final file = File(filePath);
    if (!file.existsSync()) return;

    for (final line in file.readAsLinesSync()) {
      final fields = line.split('\t');
      if (fields.length < 3) continue;
      final path = fields[0];
      final word = fields[1];
      final translation = fields[2];
      addNode(path, word, translation);
    }
  }

  void save() {
    final file = File(filePath);
    final sink = file.openWrite();
    void writeNode(TreeNode node) {
      sink.writeln('${node.path}\t${node.word}\t${node.translation}');
      node.children.values.forEach(writeNode);
    }
    root.values.forEach(writeNode);
    sink.close();
  }

  void addNode(String path, String word, String translation) {
    final segments = path.split('/');
    Map<String, TreeNode> current = root;
    for (final segment in segments) {
      current = current.putIfAbsent(segment, () => TreeNode(path, word, translation)).children;
    }
    current[segments.last] = TreeNode(path, word, translation);
  }

  void deleteNode(String path) {
    final segments = path.split('/');
    Map<String, TreeNode> current = root;
    for (int i = 0; i < segments.length - 1; i++) {
      if (!current.containsKey(segments[i])) return;
      current = current[segments[i]]!.children;
    }
    current.remove(segments.last);
  }

  void editNode(String path, String? newWord, String? newTranslation) {
    final node = findNode(path);
    if (node != null) {
      if (newWord != null) node.word = newWord;
      if (newTranslation != null) node.translation = newTranslation;
    }
  }

  TreeNode? findNode(String path) {
    final segments = path.split('/');
    Map<String, TreeNode> current = root;
    for (final segment in segments) {
      if (!current.containsKey(segment)) return null;
      current = current[segment]!.children;
    }
    return current[segments.last];
  }

  List<TreeNode> getChildren(String path) {
    final node = findNode(path);
    if (node == null) return [];
    return node.children.values.toList();
  }

  List<TreeNode> getDescendants(String path) {
    final node = findNode(path);
    if (node == null) return [];
    List<TreeNode> descendants = [];
    void collectDescendants(TreeNode currentNode) {
      currentNode.children.values.forEach((child) {
        descendants.add(child);
        collectDescendants(child);
      });
    }
    collectDescendants(node);
    return descendants;
  }
}

Future<void> main() async {
  final editor = CSVTreeEditor('tree.csv');
  editor.load();
  print('Сервер запущен на http://localhost:8080');
  
  final server = await HttpServer.bind('localhost', 8080);

  await for (HttpRequest request in server) {
    final response = request.response;
    response.headers.contentType = ContentType.json;

    final path = request.uri.path;
    final queryParameters = request.uri.queryParameters;
    
    if (path == '/node' && request.method == 'GET') {
      final nodePath = queryParameters['path'] ?? '';
      final node = editor.findNode(nodePath);
      if (node != null) {
        response.write(jsonEncode(node.toJson()));
      } else {
        response.statusCode = HttpStatus.notFound;
        response.write(jsonEncode({'error': 'Node not found'}));
      }
    } else if (path == '/node' && request.method == 'POST') {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body);
      editor.addNode(data['path'], data['word'], data['translation']);
      editor.save();
      response.write(jsonEncode({'status': 'Node added successfully'}));
    } else if (path == '/node' && request.method == 'PUT') {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body);
      editor.editNode(data['path'], data['word'], data['translation']);
      editor.save();
      response.write(jsonEncode({'status': 'Node updated successfully'}));
    } else if (path == '/node' && request.method == 'DELETE') {
      final nodePath = queryParameters['path'] ?? '';
      editor.deleteNode(nodePath);
      editor.save();
      response.write(jsonEncode({'status': 'Node deleted successfully'}));
    } else if (path == '/descendants' && request.method == 'GET') {
      final nodePath = queryParameters['path'] ?? '';
      final descendants = editor.getDescendants(nodePath).map((node) => node.toJson()).toList();
      response.write(jsonEncode(descendants));
    } else {
      response.statusCode = HttpStatus.notFound;
      response.write(jsonEncode({'error': 'Not found'}));
    }

    await response.close();
  }
}
