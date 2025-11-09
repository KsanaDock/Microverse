# ORA-ExplORA 系统开发路线图

**版本**: 1.0
**日期**: 2025-11-01
**项目概述**: 基于实时定位的五维属性系统 + Godot LLM驱动的社交游戏

---

## 项目总览

### 核心系统
1. **ORA APP** (Flutter): 实时定位追踪 + 五维属性计算 + 线下权益发放
2. **ExplORA Game** (Godot): LLM驱动的AI社交游戏 + 提示词系统
3. **后端服务**: 数据同步 + API服务 + 成就/排行榜系统

### 关键技术栈
- **ORA APP**: Flutter + Dart
- **ExplORA Game**: Godot 4 + GDScript
- **后端**: Python/Node.js (待定) + PostgreSQL/MongoDB
- **LLM**: 千问 (Qwen) via SiliconFlow API
- **定位服务**: 第三方供应商 (已确定)

---

## 📋 开发阶段划分

### 阶段 0: 系统设计与技术方案 (当前阶段)
**目标**: 完成所有核心系统的设计文档，确保技术方案可行

#### 0.1 五维属性系统设计 ⭐
**交付物**:
- [ ] 五维属性定义文档 (探索、社交、冒险、智慧、创造)
- [ ] ORA端属性计算逻辑设计
  - 线下行为 → 数据映射规则
  - 定位数据 → 属性值计算公式
  - 实时更新策略
- [ ] ExplORA端属性应用设计
  - 属性值接收和存储
  - 属性值对游戏的影响机制
- [ ] 属性数据模型设计

**关键问题**:
- ✅ 五维属性的具体定义和取值范围？(建议: 0-100分)
- ✅ 线下行为如何映射到属性值？(需要明确规则)
- ✅ 属性值更新频率？(实时 vs 批量)

---

#### 0.2 API接口设计 ⭐⭐
**交付物**:
- [ ] RESTful API规范文档
- [ ] 数据同步接口设计
  - `POST /api/v1/attributes/sync` - 属性实时同步
  - `GET /api/v1/attributes/{user_id}` - 获取用户五维属性
  - `GET /api/v1/attributes/{user_id}/history` - 属性历史记录
- [ ] 成就和排行榜接口设计
  - `GET /api/v1/achievements` - 获取成就列表
  - `GET /api/v1/achievements/{user_id}` - 用户成就进度
  - `GET /api/v1/leaderboard/{attribute_type}` - 排行榜数据
- [ ] 提示词接口设计
  - `POST /api/v1/prompts` - 提交提示词
  - `GET /api/v1/prompts/{user_id}/active` - 获取有效提示词
- [ ] WebSocket接口设计 (实时推送)
  - 属性变化通知
  - 成就解锁通知

**技术选型**:
- [ ] 后端框架选择 (FastAPI/Express/Django)
- [ ] 数据库选择 (PostgreSQL/MongoDB/Redis组合)
- [ ] 实时通信方案 (WebSocket/Server-Sent Events)

---

#### 0.3 五维属性影响LLM决策机制 ⭐⭐⭐
**交付物**:
- [ ] 属性 → Prompt注入策略
  - 探索度高 → Agent更倾向于探索新地点
  - 社交度高 → Agent更主动发起对话
  - 冒险度高 → Agent更愿意尝试冒险行为
  - 智慧度高 → Agent对话更深刻/理性
  - 创造度高 → Agent行为更创新/非传统
- [ ] Prompt模板设计
  - 基础人设 + 五维属性描述
  - 属性值 → 性格特质映射表
- [ ] 决策权重算法
  - 五维属性如何影响决策概率分布

**示例Prompt**:
```
你的探索指数是 85/100，你天生喜欢探索未知的地方。
你的社交指数是 60/100，你在社交场合表现适中。
你的冒险指数是 92/100，你极度渴望冒险和刺激。
...
基于你的这些特质，决定接下来要做什么。
```

---

#### 0.4 提示词系统设计 ⭐
**交付物**:
- [ ] 提示词输入机制
  - 字数限制: 100中文字 / 100英文单词
  - 输入验证规则
- [ ] 提示词有效期管理
  - 有效期: 5小时
  - 过期自动失效机制
  - 倒计时显示
- [ ] 提示词类型分类
  - 一次性提示词 (触发一次后失效)
  - 持续影响提示词 (5小时内持续生效)
- [ ] 内容审核策略
  - ❓ 是否需要敏感词过滤？(用户表示不需要)
  - ❓ 是否需要人工审核？(待确认)
- [ ] 提示词 → Prompt集成方式
  - 插入到Agent决策Prompt的位置
  - 优先级设计

---

#### 0.5 成就与排行榜系统设计 ⭐
**交付物**:
- [ ] 成就系统设计
  - 成就类型定义 (探索成就、社交成就、冒险成就等)
  - 成就触发条件
  - 成就奖励机制 (对应ORA的线下权益)
  - 成就进度追踪
- [ ] 排行榜设计
  - 全球排行榜 vs 好友排行榜
  - 按五维属性分别排行
  - 综合排行榜算法
  - 排行榜更新频率 (实时/每小时/每日)
- [ ] 数据结构设计
  ```json
  {
    "achievement_id": "explorer_lv1",
    "name": "初级探险家",
    "description": "探索5个不同的地点",
    "progress": {
      "current": 3,
      "target": 5
    },
    "reward": {
      "type": "offline_benefit",
      "value": "咖啡店9折券"
    }
  }
  ```

---

#### 0.6 系统架构设计 ⭐⭐
**交付物**:
- [ ] 整体架构图
  ```
  ┌─────────────┐         ┌──────────────┐
  │  ORA APP    │◄────────┤  后端服务     │
  │  (Flutter)  │  REST   │  (FastAPI)   │
  └─────────────┘  +WS    └──────┬───────┘
                                  │
  ┌─────────────┐                │
  │ 定位服务API  │────────────────┤
  └─────────────┘                │
                                  │
  ┌─────────────┐         ┌──────▼───────┐
  │ ExplORA     │◄────────┤   数据库     │
  │ (Godot)     │  REST   │ (PostgreSQL) │
  └─────────────┘         └──────────────┘
         │
         ▼
  ┌─────────────┐
  │  Qwen LLM   │
  │ (千问API)   │
  └─────────────┘
  ```
- [ ] 数据流设计
  - 定位数据流: 定位服务 → ORA APP → 后端 → 属性计算
  - 属性同步流: 后端 → ExplORA Game (WebSocket实时推送)
  - 决策流: ExplORA → 读取属性 → 构建Prompt → Qwen LLM → 决策
- [ ] 安全架构
  - 用户认证机制 (JWT)
  - API密钥管理
  - 数据加密策略

---

### 阶段 1: 后端基础设施搭建
**预估时间**: 2-3周
**依赖**: 阶段0完成

#### 1.1 后端服务开发
**任务**:
- [ ] 搭建后端项目框架
- [ ] 实现用户认证系统
- [ ] 实现基础CRUD API
- [ ] 配置数据库 (PostgreSQL + Redis)
- [ ] 实现WebSocket服务

#### 1.2 数据库设计与实现
**任务**:
- [ ] 用户表 (users)
- [ ] 五维属性表 (attributes)
- [ ] 属性历史记录表 (attribute_history)
- [ ] 成就表 (achievements)
- [ ] 用户成就表 (user_achievements)
- [ ] 排行榜缓存 (Redis)
- [ ] 提示词表 (prompts)

**数据库Schema示例**:
```sql
CREATE TABLE users (
    user_id UUID PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE attributes (
    user_id UUID REFERENCES users(user_id),
    exploration INT DEFAULT 50,
    social INT DEFAULT 50,
    adventure INT DEFAULT 50,
    wisdom INT DEFAULT 50,
    creativity INT DEFAULT 50,
    updated_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (user_id)
);

CREATE TABLE prompts (
    prompt_id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(user_id),
    content TEXT NOT NULL,
    prompt_type VARCHAR(20), -- 'one_time' or 'continuous'
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP, -- created_at + 5 hours
    is_active BOOLEAN DEFAULT TRUE
);
```

#### 1.3 API实现
**任务**:
- [ ] 属性同步API
- [ ] 成就查询API
- [ ] 排行榜API
- [ ] 提示词管理API
- [ ] WebSocket推送服务

---

### 阶段 2: ORA APP 开发 (五维属性计算端)
**预估时间**: 3-4周
**依赖**: 阶段1完成

#### 2.1 Flutter项目搭建
**任务**:
- [ ] 创建Flutter项目
- [ ] 配置路由和状态管理 (Provider/Riverpod/Bloc)
- [ ] 集成定位服务SDK
- [ ] 实现后端API客户端

#### 2.2 实时定位功能
**任务**:
- [ ] 接入第三方定位服务
- [ ] 实时位置追踪
- [ ] 后台定位权限处理
- [ ] 位置数据上传到后端

#### 2.3 五维属性计算逻辑
**任务**:
- [ ] 实现线下行为 → 属性映射算法
  - 去新地点 → 探索度 +5
  - 参加社交活动 → 社交度 +10
  - 极限运动 → 冒险度 +8
  - 阅读/学习 → 智慧度 +6
  - 艺术活动 → 创造度 +7
- [ ] 属性值本地缓存
- [ ] 属性值上传到后端

#### 2.4 UI开发
**任务**:
- [ ] 首页: 五维属性雷达图
- [ ] 成就页面: 成就列表和进度
- [ ] 排行榜页面
- [ ] 权益中心: 线下权益展示和兑换
- [ ] 设置页面

---

### 阶段 3: ExplORA 游戏核心开发 (基于Microverse)
**预估时间**: 4-5周
**依赖**: 阶段1完成

#### 3.1 Microverse代码库适配
**任务**:
- [ ] Fork Microverse项目
- [ ] 移除不需要的功能
- [ ] 重命名为ExplORA
- [ ] 配置Qwen LLM (通过SiliconFlow)

#### 3.2 五维属性集成
**任务**:
- [ ] 创建AttributeManager.gd单例
- [ ] 实现从后端API获取属性的逻辑
- [ ] 实现WebSocket监听属性变化
- [ ] 将属性数据注入到AIAgent

**代码示例**:
```gdscript
# AttributeManager.gd
extends Node

var current_attributes = {
    "exploration": 50,
    "social": 50,
    "adventure": 50,
    "wisdom": 50,
    "creativity": 50
}

func fetch_attributes(user_id: String):
    # 从后端API获取属性
    var http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request("https://api.ora.com/v1/attributes/" + user_id)

func get_attribute_description() -> String:
    return """
    你的探索指数是 %d/100
    你的社交指数是 %d/100
    你的冒险指数是 %d/100
    你的智慧指数是 %d/100
    你的创造指数是 %d/100
    """ % [current_attributes.exploration, ...]
```

#### 3.3 LLM决策机制改造
**任务**:
- [ ] 修改ConversationManager.gd的Prompt构建
- [ ] 在Prompt中注入五维属性描述
- [ ] 修改AIAgent.gd的决策逻辑
- [ ] 根据属性值调整决策权重

**Prompt改造示例**:
```gdscript
func build_decision_prompt(...):
    var prompt = "你是一个AI角色，名字是%s。\n" % character_name

    # 注入五维属性
    var attribute_desc = AttributeManager.get_attribute_description()
    prompt += "\n" + attribute_desc + "\n"

    # 根据属性调整行为倾向
    if AttributeManager.current_attributes.exploration > 70:
        prompt += "你天生热爱探索，总是想去新的地方看看。\n"

    if AttributeManager.current_attributes.social > 70:
        prompt += "你非常外向，喜欢和人聊天交流。\n"

    # ... 其他逻辑

    return prompt
```

#### 3.4 提示词系统实现
**任务**:
- [ ] 创建PromptManager.gd单例
- [ ] 实现提示词输入UI (限100字)
- [ ] 实现提示词提交到后端API
- [ ] 实现提示词有效期倒计时显示
- [ ] 将活跃提示词注入到Agent决策Prompt

**代码示例**:
```gdscript
# PromptManager.gd
extends Node

var active_prompts = []

func submit_prompt(content: String, prompt_type: String):
    if content.length() > 100:
        return {"error": "提示词超过100字限制"}

    var http_request = HTTPRequest.new()
    var data = {
        "content": content,
        "prompt_type": prompt_type  # "one_time" or "continuous"
    }
    http_request.request("https://api.ora.com/v1/prompts", [], HTTPClient.METHOD_POST, JSON.stringify(data))

func get_active_prompts() -> Array:
    # 从后端获取有效提示词 (5小时内)
    return active_prompts

func inject_prompts_to_agent_prompt(base_prompt: String) -> String:
    var prompts = get_active_prompts()
    if prompts.is_empty():
        return base_prompt

    var prompt_text = "\n\n用户当前的特殊指令：\n"
    for p in prompts:
        prompt_text += "- " + p.content + "\n"

    return base_prompt + prompt_text
```

---

### 阶段 4: 成就与排行榜系统实现
**预估时间**: 2周
**依赖**: 阶段2、阶段3完成

#### 4.1 成就追踪
**任务**:
- [ ] 在ExplORA中实现成就触发检测
- [ ] 成就进度上报到后端
- [ ] 成就解锁通知 (WebSocket推送)

#### 4.2 排行榜计算
**任务**:
- [ ] 后端实现排行榜计算逻辑
- [ ] Redis缓存排行榜数据
- [ ] 定时更新排行榜 (每小时)

#### 4.3 ORA APP集成
**任务**:
- [ ] ORA APP展示成就列表
- [ ] ORA APP展示排行榜
- [ ] 成就对应的线下权益发放

---

### 阶段 5: Flutter ↔ Godot 集成
**预估时间**: 1-2周
**依赖**: 阶段2、阶段3完成

#### 5.1 原生模块开发
**任务**:
- [ ] 调研Flutter如何启动Godot游戏
  - 方案1: 使用Platform Channel调用原生代码启动Godot
  - 方案2: 将Godot导出为Android/iOS库
  - 方案3: 使用WebView加载Godot Web版
- [ ] 实现ORA APP → ExplORA的跳转
- [ ] 实现数据传递 (user_id等)

#### 5.2 测试集成
**任务**:
- [ ] Android平台测试
- [ ] iOS平台测试
- [ ] 数据同步测试

---

### 阶段 6: 测试与优化
**预估时间**: 2-3周
**依赖**: 所有阶段完成

#### 6.1 功能测试
**任务**:
- [ ] 定位功能测试
- [ ] 属性计算准确性测试
- [ ] LLM决策测试
- [ ] 提示词系统测试
- [ ] 成就解锁测试
- [ ] 排行榜准确性测试

#### 6.2 性能优化
**任务**:
- [ ] API响应时间优化
- [ ] 数据库查询优化
- [ ] WebSocket连接稳定性优化
- [ ] Godot游戏性能优化

#### 6.3 安全测试
**任务**:
- [ ] API安全测试
- [ ] 用户数据隐私保护
- [ ] 防作弊机制

---

### 阶段 7: 上线准备
**预估时间**: 1-2周

#### 7.1 部署
**任务**:
- [ ] 后端服务部署 (云服务器/容器化)
- [ ] 数据库部署和备份策略
- [ ] CDN配置
- [ ] 监控系统搭建

#### 7.2 发布
**任务**:
- [ ] ORA APP发布到App Store / Google Play
- [ ] ExplORA游戏打包
- [ ] 用户文档编写

---

## 🎯 关键里程碑

| 里程碑 | 完成标准 | 预估时间 |
|--------|----------|----------|
| M0: 设计完成 | 所有设计文档通过审核 | 1周 |
| M1: 后端可用 | API全部实现并测试通过 | 3周 |
| M2: ORA APP Alpha | 定位和属性计算功能可用 | 6周 |
| M3: ExplORA Alpha | 游戏可玩，LLM决策生效 | 10周 |
| M4: 集成测试通过 | ORA ↔ ExplORA数据同步正常 | 12周 |
| M5: Beta版本 | 所有核心功能完成 | 14周 |
| M6: 正式发布 | 通过所有测试，上线 | 16周 |

---

## ⚠️ 风险与挑战

### 技术风险
1. **Flutter ↔ Godot集成复杂度**
   - 风险等级: 🔴 高
   - 缓解策略: 提前进行技术验证，选择最可行的方案

2. **实时数据同步性能**
   - 风险等级: 🟡 中
   - 缓解策略: 使用WebSocket + Redis，设计高效的推送机制

3. **LLM API调用成本**
   - 风险等级: 🟡 中
   - 缓解策略: 优化Prompt长度，实现缓存机制

### 业务风险
1. **五维属性计算公平性**
   - 风险等级: 🟡 中
   - 缓解策略: 设计合理的算法，防止作弊

2. **用户隐私和定位数据安全**
   - 风险等级: 🔴 高
   - 缓解策略: 严格的数据加密和隐私政策

---

## 📊 资源需求

### 开发人员
- **后端工程师**: 1-2人
- **Flutter工程师**: 1人
- **Godot工程师**: 1人 (可兼任后端)
- **UI/UX设计师**: 1人

### 基础设施
- **云服务器**: 1台 (8核16G，可扩展)
- **数据库**: PostgreSQL + Redis
- **LLM API**: Qwen (SiliconFlow)
- **定位服务**: 第三方供应商

### 预算估算
- **开发成本**: 根据团队规模
- **云服务**: ~$200-500/月
- **LLM API**: 按调用次数计费 (需根据用户量估算)
- **定位服务**: 已确定供应商，在预算内

---

## ❓ 待确认的问题

1. **五维属性的具体定义**
   - 探索、社交、冒险、智慧、创造 各代表什么？
   - 取值范围是0-100吗？

2. **线下行为 → 属性映射规则**
   - 具体什么行为增加什么属性？
   - 增加幅度如何设计？

3. **提示词内容审核**
   - 是否需要敏感词过滤？
   - 是否需要人工审核？

4. **成就和权益设计**
   - 具体有哪些成就？
   - 对应什么线下权益？

5. **Flutter ↔ Godot集成方案**
   - 采用哪种技术方案？
   - 需要提前验证可行性

---

## 📝 下一步行动

### 立即开始 (阶段0)
1. ✅ 探索Microverse代码库 (已完成)
2. ⏳ 设计五维属性计算逻辑
3. ⏳ 设计API接口规范
4. ⏳ 设计五维属性对LLM的影响机制
5. ⏳ 设计提示词系统细节
6. ⏳ 设计成就和排行榜数据结构

### 需要您的反馈
- 请确认五维属性的具体定义
- 请提供线下行为 → 属性映射的初步想法
- 请确认提示词是否需要审核
- 请确认Flutter ↔ Godot集成的偏好方案

---

**文档版本控制**:
- v1.0 (2025-11-01): 初始版本
