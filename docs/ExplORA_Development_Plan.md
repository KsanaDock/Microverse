# ExplORA 开发实施计划

**版本**: 1.0
**日期**: 2025-11-01
**基于**: Microverse 源代码

---

## 🎯 开发目标

将 ORA-ExplORA 系统设计集成到 Microverse，实现：
1. ✅ 五维属性系统驱动 AI 行为
2. ✅ 提示词系统影响游戏世界
3. ✅ 在 Godot 中可测试运行
4. ✅ 使用模拟数据（暂不连接真实后端）

---

## 📋 开发阶段

### 阶段 1: 基础架构 🏗️
**目标**: 创建核心管理器单例，建立数据基础

#### 任务 1.1: 创建 AttributeManager.gd
- [x] 管理五维属性数据
- [x] 提供属性查询接口
- [x] 生成属性描述文本（用于Prompt）
- [x] 模拟属性数据（测试用）

#### 任务 1.2: 创建 PromptManager.gd
- [x] 管理用户提示词
- [x] 提示词有效期管理（5小时）
- [x] 提供提示词查询接口
- [x] 模拟提示词数据

#### 任务 1.3: 配置 project.godot
- [x] 添加 AttributeManager 到 autoload
- [x] 添加 PromptManager 到 autoload

**完成标准**: 在 Godot 中运行，可以通过调试打印看到属性数据

---

### 阶段 2: AI 决策集成 🤖
**目标**: 将五维属性注入到 AI 决策 Prompt

#### 任务 2.1: 修改 AIAgent.gd
- [x] 在 `make_decision()` 中读取五维属性
- [x] 在 Prompt 中注入属性描述
- [x] 在 Prompt 中注入用户提示词

#### 任务 2.2: 修改 ConversationManager.gd
- [x] 在 `build_dialog_prompt()` 中注入属性描述
- [x] 根据属性调整对话风格指导

**完成标准**: AI 的决策和对话开始受属性影响，可通过调整属性值观察行为变化

---

### 阶段 3: 调试工具 UI 🛠️
**目标**: 创建方便的测试工具，可视化调整属性

#### 任务 3.1: 创建 AttributeDebugger.gd + UI
- [x] 显示当前五维属性值
- [x] 提供滑块调整属性（0-1000）
- [x] 实时更新 AttributeManager
- [x] 显示当前属性对应的性格描述

#### 任务 3.2: 集成到游戏场景
- [x] 添加快捷键打开调试面板（如 F1）
- [x] 面板可隐藏/显示

**完成标准**: 可以通过UI实时调整属性，观察AI行为变化

---

### 阶段 4: 提示词系统 UI 💬
**目标**: 允许玩家输入提示词影响游戏

#### 任务 4.1: 创建 PromptInput.gd + UI
- [x] 文本输入框（限制100字）
- [x] 字数计数显示
- [x] 提示词类型选择（一次性/持续影响）
- [x] 提交按钮

#### 任务 4.2: 提示词显示
- [x] 显示当前活跃提示词列表
- [x] 显示剩余有效时间倒计时
- [x] 可删除提示词

**完成标准**: 玩家可输入提示词，AI 行为受提示词影响

---

### 阶段 5: 测试与优化 🧪
**目标**: 验证系统效果，调优 Prompt

#### 任务 5.1: 功能测试
- [ ] 测试不同属性值的 AI 行为差异
- [ ] 测试提示词的影响效果
- [ ] 测试 LLM API 调用

#### 任务 5.2: Prompt 优化
- [ ] 根据测试结果调整属性描述文本
- [ ] 优化 Prompt 结构和长度
- [ ] 调整 LLM 参数（temperature 等）

#### 任务 5.3: 用户体验优化
- [ ] UI 美化
- [ ] 添加提示和说明
- [ ] 错误处理

**完成标准**: 系统稳定运行，AI 行为符合预期

---

## 🛠️ 开发顺序

```
Day 1-2: 阶段1 - 基础架构
  ├─ 创建 AttributeManager.gd
  ├─ 创建 PromptManager.gd
  └─ 配置 autoload

Day 3-4: 阶段2 - AI集成
  ├─ 修改 AIAgent.gd
  └─ 修改 ConversationManager.gd

Day 5: 阶段3 - 调试工具
  └─ 创建 AttributeDebugger UI

Day 6: 阶段4 - 提示词UI
  └─ 创建 PromptInput UI

Day 7+: 阶段5 - 测试优化
  └─ 持续测试和改进
```

---

## 📁 新增文件清单

### 脚本文件
```
script/
├── attribute/
│   ├── AttributeManager.gd          # 五维属性管理器（新增）
│   └── AttributeDescriptions.gd     # 属性描述生成（新增）
├── prompt/
│   └── PromptManager.gd             # 提示词管理器（新增）
└── ui/
    ├── AttributeDebugger.gd         # 属性调试UI（新增）
    └── PromptInput.gd               # 提示词输入UI（新增）
```

### 场景文件
```
scenes/ui/
├── AttributeDebugger.tscn           # 属性调试面板（新增）
└── PromptInput.tscn                 # 提示词输入面板（新增）
```

---

## 🔧 核心代码片段预览

### AttributeManager.gd (简化版)
```gdscript
extends Node

var current_attributes = {
    "cognition": 500,
    "sociability": 500,
    "charisma": 500,
    "vitality": 500,
    "reflection": 500
}

func get_all_descriptions() -> String:
    var desc = ""
    desc += get_cognition_description() + "\n"
    desc += get_sociability_description() + "\n"
    desc += get_charisma_description() + "\n"
    desc += get_vitality_description() + "\n"
    desc += get_reflection_description() + "\n"
    return desc

func set_attribute(attr_name: String, value: int):
    current_attributes[attr_name] = clamp(value, 0, 1000)
```

### 修改 AIAgent.gd (决策部分)
```gdscript
func make_decision():
    var prompt = build_decision_prompt()

    # 注入五维属性
    var attr_desc = AttributeManager.get_all_descriptions()
    prompt = attr_desc + "\n\n" + prompt

    # 注入用户提示词
    var user_prompts = PromptManager.get_active_prompts()
    if not user_prompts.is_empty():
        prompt += "\n\n用户指令:\n"
        for p in user_prompts:
            prompt += "- " + p.content + "\n"

    # 调用 LLM
    var api_manager = APIManager.get_instance()
    ...
```

---

## 🎮 测试场景设计

### 测试用例 1: 高认知角色
- **属性设置**: Cognition=900, 其他=300
- **预期行为**: 频繁去图书馆，对话充满智慧，主动参加讲座
- **测试方法**: 观察15分钟，记录行为

### 测试用例 2: 高社交角色
- **属性设置**: Sociability=900, 其他=300
- **预期行为**: 频繁发起对话，去社交区，组织活动
- **测试方法**: 观察与其他角色的互动次数

### 测试用例 3: 内向疲惫角色
- **属性设置**: Sociability=100, Vitality=150, 其他=500
- **预期行为**: 独处、找安静角落、避开人群、对话消极
- **测试方法**: 观察位置选择和对话内容

### 测试用例 4: 提示词影响
- **提示词**: "今天想认识新朋友"
- **预期行为**: 即使 Sociability 不高，也会主动社交
- **测试方法**: 对比提示词前后的行为变化

---

## 📊 成功指标

### 技术指标
- ✅ 五维属性成功注入到 Prompt
- ✅ AI 决策受属性影响，行为有差异
- ✅ 提示词系统正常工作
- ✅ UI 可用性良好

### 效果指标
- ✅ 高 vs 低属性的 AI 行为差异明显（>70%差异率）
- ✅ 用户能通过调整属性看到立即的行为变化
- ✅ 提示词对 AI 行为有可见影响
- ✅ LLM 响应符合预期（<5秒响应时间）

---

## ⚠️ 注意事项

### 开发注意事项
1. **先用模拟数据**: 不要立即连接后端 API，用硬编码数据测试
2. **频繁测试**: 每完成一个小功能就在 Godot 中运行测试
3. **调试输出**: 大量使用 `print()` 输出关键信息
4. **版本控制**: 每完成一个阶段就 git commit

### LLM API 注意事项
1. **API 配置**: 确保 SiliconFlow API 密钥已配置
2. **成本控制**: 测试时频繁调用 API 可能产生费用
3. **错误处理**: 实现 API 调用失败的降级处理
4. **Prompt 长度**: 控制 Prompt 长度，避免超过 token 限制

---

## 🚀 现在开始！

**第一步**: 创建 AttributeManager.gd 和 PromptManager.gd
**第二步**: 配置 project.godot
**第三步**: 在 Godot 中测试加载

准备好了吗？让我们开始编码！

---

**最后更新**: 2025-11-01
