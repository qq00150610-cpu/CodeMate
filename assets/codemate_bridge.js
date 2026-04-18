// codemate_bridge.js
// CodeMate JavaScript 桥接脚本
// 用于 WebView 中的 code-server 与 Flutter/Android 通信

(function() {
    'use strict';

    // 防止重复加载
    if (window.CodeMateBridge) {
        console.log('[CodeMateBridge] Already initialized');
        return;
    }

    // ============================================================================
    // CodeMate 桥接对象
    // ============================================================================
    window.CodeMateBridge = {
        version: '1.0.0',
        initialized: false,
        
        // 回调函数
        _callbacks: {},
        _eventListeners: {},
        
        // ============================================================================
        // 初始化
        // ============================================================================
        init: function() {
            if (this.initialized) return;
            
            console.log('[CodeMateBridge] Initializing...');
            
            // 监听 VSCode 就绪事件
            this._waitForVSCode();
            
            this.initialized = true;
            console.log('[CodeMateBridge] Initialized');
        },

        // 等待 VSCode 加载完成
        _waitForVSCode: function() {
            const checkVSCode = () => {
                if (window.monaco && window.monaco.editor) {
                    console.log('[CodeMateBridge] VSCode detected');
                    this._setupEditorBridge();
                    this._setupCommandPalette();
                } else {
                    setTimeout(checkVSCode, 500);
                }
            };
            checkVSCode();
        },

        // 设置编辑器桥接
        _setupEditorBridge: function() {
            // 获取活动编辑器
            const getActiveEditor = () => {
                return window.monaco?.editor?.getActiveCodeEditor?.();
            };

            // 插入文本
            this.insertText = function(text) {
                const editor = getActiveEditor();
                if (editor) {
                    const position = editor.getPosition();
                    const range = new monaco.Range(
                        position.lineNumber,
                        position.column,
                        position.lineNumber,
                        position.column
                    );
                    editor.executeEdits('codemate', [{
                        range: range,
                        text: text
                    }]);
                    return true;
                }
                return false;
            };

            // 带光标定位的文本插入
            this.insertTextWithCursor = function(text, cursorOffset) {
                const editor = getActiveEditor();
                if (editor) {
                    const position = editor.getPosition();
                    const fullText = text.substring(0, cursorOffset) + 
                                    text.substring(cursorOffset);
                    const range = new monaco.Range(
                        position.lineNumber,
                        position.column,
                        position.lineNumber,
                        position.column
                    );
                    editor.executeEdits('codemate', [{
                        range: range,
                        text: fullText
                    }]);
                    // 移动光标
                    const newColumn = position.column + cursorOffset;
                    editor.setPosition({ lineNumber: position.lineNumber, column: newColumn });
                    return true;
                }
                return false;
            };

            // 在光标位置插入文本
            this.insertTextAtCursor = function(text) {
                return this.insertText(text);
            };

            // 执行命令
            this.executeCommand = function(command) {
                const editor = getActiveEditor();
                if (editor) {
                    // 常见命令映射
                    const commandMap = {
                        'undo': 'undo',
                        'redo': 'redo',
                        'save': 'workbench.action.files.save',
                        'copy': 'editor.action.clipboardCopyAction',
                        'cut': 'editor.action.clipboardCutAction',
                        'paste': 'editor.action.clipboardPasteAction',
                        'selectAll': 'editor.action.selectAll',
                        'find': 'actions.find',
                        'replace': 'editor.action.startFindReplaceAction',
                        'format': 'editor.action.formatDocument'
                    };
                    
                    const vsCommand = commandMap[command] || command;
                    editor.trigger('keyboard', vsCommand, null);
                    return true;
                }
                return false;
            };

            // 获取选中文本
            this.getSelection = function() {
                const editor = getActiveEditor();
                if (editor) {
                    const selection = editor.getSelection();
                    if (selection) {
                        const model = editor.getModel();
                        return model?.getValueInRange(selection) || '';
                    }
                }
                return '';
            };

            // 获取当前文件信息
            this.getCurrentFile = function() {
                const editor = getActiveEditor();
                if (editor) {
                    const model = editor.getModel();
                    return {
                        uri: model?.uri?.toString() || '',
                        language: model?.getLanguageId() || '',
                        lineCount: model?.getLineCount() || 0
                    };
                }
                return null;
            };

            console.log('[CodeMateBridge] Editor bridge setup complete');
        },

        // 设置命令面板桥接
        _setupCommandPalette: function() {
            // 显示命令面板
            this.showCommandPalette = function() {
                // 模拟 Ctrl+Shift+P
                document.dispatchEvent(new KeyboardEvent('keydown', {
                    key: 'p',
                    code: 'KeyP',
                    ctrlKey: true,
                    shiftKey: true
                }));
                return true;
            };

            console.log('[CodeMateBridge] Command palette bridge setup complete');
        },

        // ============================================================================
        // 消息发送
        // ============================================================================
        
        // 发送消息到原生层
        sendToNative: function(type, data) {
            try {
                const message = JSON.stringify({
                    type: type,
                    data: data,
                    timestamp: Date.now()
                });
                
                if (window.CodeMateJS && window.CodeMateJS.onMessage) {
                    window.CodeMateJS.onMessage(message);
                    return true;
                }
                
                // 尝试通过 Flutter 通道
                if (window.flutter_channel) {
                    window.flutter_channel.postMessage(message);
                    return true;
                }
                
                console.warn('[CodeMateBridge] No native bridge available');
                return false;
            } catch (e) {
                console.error('[CodeMateBridge] Send error:', e);
                return false;
            }
        },

        // ============================================================================
        // 事件系统
        // ============================================================================

        // 添加事件监听器
        on: function(event, callback) {
            if (!this._eventListeners[event]) {
                this._eventListeners[event] = [];
            }
            this._eventListeners[event].push(callback);
        },

        // 移除事件监听器
        off: function(event, callback) {
            if (!this._eventListeners[event]) return;
            const index = this._eventListeners[event].indexOf(callback);
            if (index > -1) {
                this._eventListeners[event].splice(index, 1);
            }
        },

        // 触发事件
        _emit: function(event, data) {
            if (!this._eventListeners[event]) return;
            this._eventListeners[event].forEach(callback => {
                try {
                    callback(data);
                } catch (e) {
                    console.error('[CodeMateBridge] Event handler error:', e);
                }
            });
        },

        // ============================================================================
        // 快捷键处理
        // ============================================================================

        // 处理快捷键
        handleQuickKey: function(key) {
            switch (key) {
                case 'tab':
                    this.insertText('\t');
                    break;
                case 'brace':
                    this.insertTextWithCursor('{}', 1);
                    break;
                case 'paren':
                    this.insertTextWithCursor('()', 1);
                    break;
                case 'comment':
                    this.insertText('// ');
                    break;
                case 'semicolon':
                    this.insertText(';');
                    break;
                case 'undo':
                    this.executeCommand('undo');
                    break;
                case 'redo':
                    this.executeCommand('redo');
                    break;
                default:
                    console.warn('[CodeMateBridge] Unknown quick key:', key);
            }
        },

        // ============================================================================
        // AI 集成
        // ============================================================================

        // 获取代码上下文
        getCodeContext: function() {
            const selection = this.getSelection();
            const file = this.getCurrentFile();
            
            return {
                selectedCode: selection,
                fileName: file?.uri?.split('/').pop() || '',
                language: file?.language || '',
                fileInfo: file
            };
        },

        // 发送代码给 AI
        sendToAI: function(message, options) {
            const context = this.getCodeContext();
            this.sendToNative('ai_request', {
                message: message,
                code: context.selectedCode,
                language: context.language,
                fileName: context.fileName,
                options: options || {}
            });
        },

        // ============================================================================
        // 工具方法
        // ============================================================================

        // 检查初始化状态
        isReady: function() {
            return this.initialized && window.monaco?.editor != null;
        },

        // 获取状态
        getStatus: function() {
            return {
                initialized: this.initialized,
                vscodeReady: window.monaco?.editor != null,
                version: this.version
            };
        }
    };

    // ============================================================================
    // 初始化
    // ============================================================================
    
    // 页面加载完成后初始化
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
            window.CodeMateBridge.init();
        });
    } else {
        window.CodeMateBridge.init();
    }

    // ============================================================================
    // Android JavaScript Interface 兼容
    // ============================================================================
    
    window.CodeMateJS = {
        onMessage: function(message) {
            console.log('[CodeMateJS] Message received:', message);
            // 消息将通过 MethodChannel 发送到 Flutter
        }
    };

    console.log('[CodeMateBridge] Script loaded');

})();
