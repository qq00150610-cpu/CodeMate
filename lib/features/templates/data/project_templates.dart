// lib/features/templates/data/project_templates.dart
// 项目模板数据

/// 模板类别
enum TemplateCategory {
  android,
  flutter,
  web,
  backend,
  misc,
}

/// 项目模板
class ProjectTemplate {
  final String id;
  final String name;
  final String description;
  final TemplateCategory category;
  final String icon;
  final List<String> tags;
  final Map<String, String> files; // 文件路径 -> 内容
  final List<String> dependencies;
  final String? setupCommand;

  const ProjectTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    this.tags = const [],
    this.files = const {},
    this.dependencies = const [],
    this.setupCommand,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category.name,
        'icon': icon,
        'tags': tags,
        'fileCount': files.length,
        'dependencies': dependencies,
        'setupCommand': setupCommand,
      };
}

/// 预置模板集合
class ProjectTemplates {
  // ========== Android 开发模板 ==========

  static const emptyAndroid = ProjectTemplate(
    id: 'android_empty',
    name: 'Empty Android App',
    description: '基础的 Android 应用，使用 Kotlin 开发',
    category: TemplateCategory.android,
    icon: '📱',
    tags: ['Kotlin', 'Android'],
    files: {
      'app/src/main/AndroidManifest.xml': '''<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/Theme.AppCompat.Light.DarkActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>''',
      'app/src/main/kotlin/com/example/MainActivity.kt': '''package com.example

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
    }
}''',
      'app/src/main/res/layout/activity_main.xml': '''<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:gravity="center">

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Hello, World!" />

</LinearLayout>''',
      'app/build.gradle': '''plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android'
}

android {
    namespace 'com.example'
    compileSdk 34

    defaultConfig {
        applicationId "com.example"
        minSdk 24
        targetSdk 34
    }

    buildTypes {
        release {
            minifyEnabled false
        }
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
}''',
    },
    setupCommand: './gradlew assembleDebug',
  );

  static const mvvmTemplate = ProjectTemplate(
    id: 'android_mvvm',
    name: 'MVVM Architecture',
    description: '采用 MVVM 架构的 Android 应用模板',
    category: TemplateCategory.android,
    icon: '🏗️',
    tags: ['Kotlin', 'MVVM', 'Architecture'],
    files: {
      'app/src/main/kotlin/com/example/ui/MainActivity.kt': '''package com.example.ui

import android.os.Bundle
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import com.example.databinding.ActivityMainBinding
import com.example.viewmodel.MainViewModel

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding
    private val viewModel: MainViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        setupObservers()
        setupListeners()
    }

    private fun setupObservers() {
        viewModel.data.observe(this) { data ->
            binding.textView.text = data
        }
    }

    private fun setupListeners() {
        binding.button.setOnClickListener {
            viewModel.loadData()
        }
    }
}''',
      'app/src/main/kotlin/com/example/viewmodel/MainViewModel.kt': '''package com.example.viewmodel

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel

class MainViewModel : ViewModel() {
    private val _data = MutableLiveData<String>()
    val data: LiveData<String> = _data

    fun loadData() {
        _data.value = "Data loaded!"
    }
}''',
    },
  );

  // ========== Flutter 开发模板 ==========

  static const flutterBasic = ProjectTemplate(
    id: 'flutter_basic',
    name: 'Flutter Basic App',
    description: '基础的 Flutter 应用模板',
    category: TemplateCategory.flutter,
    icon: '🦋',
    tags: ['Flutter', 'Dart'],
    files: {
      'lib/main.dart': '''import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Demo'),
      ),
      body: const Center(
        child: Text('Hello, World!'),
      ),
    );
  }
}''',
      'pubspec.yaml': '''name: my_app
description: A new Flutter project.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true''',
    },
    setupCommand: 'flutter pub get && flutter run',
  );

  static const flutterProvider = ProjectTemplate(
    id: 'flutter_provider',
    name: 'Provider Architecture',
    description: '使用 Provider 状态管理的 Flutter 模板',
    category: TemplateCategory.flutter,
    icon: '📦',
    tags: ['Flutter', 'Provider', 'Architecture'],
    files: {
      'lib/main.dart': '''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/counter_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CounterProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Provider Demo',
      home: const HomeScreen(),
    );
  }
}''',
      'lib/providers/counter_provider.dart': '''import 'package:flutter/foundation.dart';

class CounterProvider extends ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }

  void decrement() {
    _count--;
    notifyListeners();
  }

  void reset() {
    _count = 0;
    notifyListeners();
  }
}''',
      'lib/screens/home_screen.dart': '''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/counter_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Demo'),
      ),
      body: Center(
        child: Consumer<CounterProvider>(
          builder: (context, counter, _) => Text(
            'Count: \${counter.count}',
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<CounterProvider>().increment(),
        child: const Icon(Icons.add),
      ),
    );
  }
}''',
    },
  );

  // ========== Web 开发模板 ==========

  static const htmlBasic = ProjectTemplate(
    id: 'web_html_basic',
    name: 'HTML/CSS/JS Basic',
    description: '基础的 HTML5 网站模板',
    category: TemplateCategory.web,
    icon: '🌐',
    tags: ['HTML', 'CSS', 'JavaScript'],
    files: {
      'index.html': '''<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Website</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <header>
        <h1>Welcome</h1>
    </header>
    <main>
        <p>Hello, World!</p>
    </main>
    <script src="script.js"></script>
</body>
</html>''',
      'styles.css': '''* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    line-height: 1.6;
    color: #333;
}

header {
    background: #333;
    color: #fff;
    padding: 1rem;
    text-align: center;
}

main {
    max-width: 800px;
    margin: 2rem auto;
    padding: 0 1rem;
}''',
      'script.js': '''document.addEventListener('DOMContentLoaded', () => {
    console.log('Page loaded!');
});''',
    },
  );

  static const reactTemplate = ProjectTemplate(
    id: 'web_react',
    name: 'React App',
    description: 'React + Vite 项目模板',
    category: TemplateCategory.web,
    icon: '⚛️',
    tags: ['React', 'Vite', 'JavaScript'],
    files: {
      'package.json': '''{
  "name": "my-react-app",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.0.0",
    "vite": "^5.0.0"
  }
}''',
      'vite.config.js': '''import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
})''',
      'index.html': '''<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>React App</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>''',
      'src/main.jsx': '''import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)''',
      'src/App.jsx': '''function App() {
  return (
    <div>
      <h1>Hello, React!</h1>
    </div>
  )
}

export default App''',
    },
    setupCommand: 'npm install && npm run dev',
  );

  // ========== 后端开发模板 ==========

  static const pythonFlask = ProjectTemplate(
    id: 'backend_flask',
    name: 'Python Flask API',
    description: 'Python Flask REST API 模板',
    category: TemplateCategory.backend,
    icon: '🐍',
    tags: ['Python', 'Flask', 'REST API'],
    files: {
      'requirements.txt': '''flask==3.0.0
flask-cors==4.0.0
python-dotenv==1.0.0''',
      'app.py': '''from flask import Flask, jsonify, request
from flask_cors import CORS
import os

app = Flask(__name__)
CORS(app)

@app.route('/api/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok'})

@app.route('/api/items', methods=['GET'])
def get_items():
    items = [
        {'id': 1, 'name': 'Item 1'},
        {'id': 2, 'name': 'Item 2'},
    ]
    return jsonify(items)

@app.route('/api/items', methods=['POST'])
def create_item():
    data = request.json
    return jsonify({'id': 3, **data}), 201

if __name__ == '__main__':
    app.run(debug=True, port=5000)''',
      '.env.example': '''FLASK_APP=app.py
FLASK_ENV=development
SECRET_KEY=your-secret-key''',
    },
    setupCommand: 'pip install -r requirements.txt && python app.py',
  );

  static const nodeExpress = ProjectTemplate(
    id: 'backend_express',
    name: 'Node.js Express API',
    description: 'Node.js Express REST API 模板',
    category: TemplateCategory.backend,
    icon: '🟢',
    tags: ['Node.js', 'Express', 'REST API'],
    files: {
      'package.json': '''{
  "name": "express-api",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": {
    "start": "node app.js",
    "dev": "nodemon app.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}''',
      'app.js': '''const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Routes
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/api/items', (req, res) => {
  const items = [
    { id: 1, name: 'Item 1' },
    { id: 2, name: 'Item 2' },
  ];
  res.json(items);
});

app.post('/api/items', (req, res) => {
  const newItem = { id: Date.now(), ...req.body };
  res.status(201).json(newItem);
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});''',
      '.env.example': '''PORT=3000
NODE_ENV=development''',
    },
    setupCommand: 'npm install && npm run dev',
  );

  static const goHttp = ProjectTemplate(
    id: 'backend_go',
    name: 'Go HTTP Server',
    description: 'Go HTTP 服务器模板',
    category: TemplateCategory.backend,
    icon: '🔵',
    tags: ['Go', 'HTTP', 'REST API'],
    files: {
      'go.mod': '''module myapp

go 1.21''',
      'main.go': '''package main

import (
    "encoding/json"
    "log"
    "net/http"
)

type Item struct {
    ID   int    \`json:"id"\`
    Name string \`json:"name"\`
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
    json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func itemsHandler(w http.ResponseWriter, r *http.Request) {
    items := []Item{
        {ID: 1, Name: "Item 1"},
        {ID: 2, Name: "Item 2"},
    }
    json.NewEncoder(w).Encode(items)
}

func main() {
    http.HandleFunc("/api/health", healthHandler)
    http.HandleFunc("/api/items", itemsHandler)
    
    log.Println("Server starting on :8080")
    log.Fatal(http.ListenAndServe(":8080", nil))
}''',
    },
    setupCommand: 'go run main.go',
  );

  // ========== 其他模板 ==========

  static const markdownDoc = ProjectTemplate(
    id: 'misc_markdown',
    name: 'Markdown Document',
    description: 'Markdown 文档模板',
    category: TemplateCategory.misc,
    icon: '📄',
    tags: ['Markdown', 'Documentation'],
    files: {
      'README.md': '''# Project Title

## 简介

项目简介...

## 功能特性

- 功能 1
- 功能 2
- 功能 3

## 安装

\`\`\`bash
npm install
\`\`\`

## 使用

\`\`\`javascript
const app = require('./app');
app.start();
\`\`\`

## 许可证

MIT License''',
    },
  );

  static const shellScripts = ProjectTemplate(
    id: 'misc_shell',
    name: 'Shell Script Collection',
    description: '常用 Shell 脚本集合',
    category: TemplateCategory.misc,
    icon: '🐚',
    tags: ['Shell', 'Bash', 'Scripts'],
    files: {
      'backup.sh': '''#!/bin/bash
# 备份脚本

BACKUP_DIR="/tmp/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "Starting backup at $DATE"
# 添加你的备份逻辑
echo "Backup completed: $BACKUP_DIR/backup_$DATE.tar.gz"''',
      'deploy.sh': '''#!/bin/bash
# 部署脚本

echo "Deploying application..."

# 构建
npm run build

# 部署到服务器
# rsync -avz ./dist/ user@server:/var/www/app

echo "Deployment completed!"''',
      'docker-up.sh': '''#!/bin/bash
# Docker Compose 启动脚本

docker-compose up -d
echo "Services started"
docker-compose ps''',
    },
  );

  /// 获取所有模板
  static List<ProjectTemplate> get all => [
        emptyAndroid,
        mvvmTemplate,
        flutterBasic,
        flutterProvider,
        htmlBasic,
        reactTemplate,
        pythonFlask,
        nodeExpress,
        goHttp,
        markdownDoc,
        shellScripts,
      ];

  /// 按类别获取模板
  static List<ProjectTemplate> byCategory(TemplateCategory category) =>
      all.where((t) => t.category == category).toList();

  /// 搜索模板
  static List<ProjectTemplate> search(String query) {
    final lowerQuery = query.toLowerCase();
    return all.where((t) {
      return t.name.toLowerCase().contains(lowerQuery) ||
          t.description.toLowerCase().contains(lowerQuery) ||
          t.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }
}
